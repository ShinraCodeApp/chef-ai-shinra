import {
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';
import {
  AiProvider,
  IngredientNutritionData,
  DetectedIngredient,
  DetectedReceiptItem,
  GenerateDailyMealPlanInput,
  GenerateRecipeInput,
  GeneratedDailyMealPlan,
  GeneratedRecipe,
  HealthAdvice,
  HealthAdviceInput,
  MealAnalysis,
} from '../ai-provider.interface';
import { MealType } from '../../../common/enums';
import { extractJson } from '../utils/extract-json';

// Modelos gratuitos en orden de preferencia (todos aceptan imágenes). Si uno
// está saturado (503) o sin cuota (429) se reintenta poco y se pasa al
// siguiente; si la key no tiene acceso a uno (404) se saltea. Con un solo
// modelo, cuando gemini-3.8-flash estaba saturado la receta fallaba siempre.
const TEXT_MODELS = [
  'gemini-3.8-flash',
  'gemini-flash-latest',
  'gemini-3.5-flash-lite',
  'gemini-flash-lite-latest',
];
const VISION_MODELS = TEXT_MODELS;
const MAX_RETRIES = 2;
const RETRY_DELAY_MS = 3000;

// Último respaldo para las funciones de texto (gratis): Groq, si hay GROQ_API_KEY.
const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.3-70b-versatile';

export function isBusyError(msg: string): boolean {
  return /\b(503|429)\b|UNAVAILABLE|RESOURCE_EXHAUSTED|overloaded|high demand/i.test(
    msg,
  );
}

// Las mismas claves que muestra la app (app/lib/core/diet_tags.dart). Sin esta
// regla la IA inventaba etiquetas en inglés ("Vegetarian").
const DIET_TAGS_RULE =
  '"dietTags" solo puede usar estos valores exactos (en minúscula, los que apliquen, o un array vacío): ' +
  'proteico, vegetariano, vegano, sin_tacc, keto, fitness, economico, comida_cruda, ' +
  'hipotiroidismo, hipertiroidismo, bajo_yodo. ' +
  'Los textos (título, descripción, pasos, ingredientes) van en castellano rioplatense.';

const BUSY_MESSAGE =
  'La IA está con mucha demanda en este momento. Probá de nuevo en un minuto.';

@Injectable()
export class GeminiProvider implements AiProvider {
  private readonly logger = new Logger(GeminiProvider.name);
  private readonly client: GoogleGenAI | null;

  constructor(private readonly configService: ConfigService) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (apiKey) {
      this.client = new GoogleGenAI({ apiKey });
    } else {
      this.client = null;
      this.logger.warn(
        'GEMINI_API_KEY no configurada — los endpoints de IA fallarán hasta que se configure.',
      );
    }
  }

  private getClient(): GoogleGenAI {
    if (!this.client) {
      throw new InternalServerErrorException(
        'La IA (Gemini) no está configurada en el servidor. Falta GEMINI_API_KEY.',
      );
    }
    return this.client;
  }

  private handleGeminiError(error: unknown, context: string): never {
    const msg = error instanceof Error ? error.message : String(error);
    this.logger.error(`Gemini error [${context}]: ${msg}`);
    // Al usuario nunca le llega el JSON técnico de Google en inglés.
    throw new InternalServerErrorException(
      isBusyError(msg)
        ? BUSY_MESSAGE
        : 'La IA no pudo responder. Probá de nuevo.',
    );
  }

  private async generateWithFallback(
    models: string[],
    buildContents: () =>
      | string
      | Array<{
          text?: string;
          inlineData?: { data: string; mimeType: string };
        }>,
    context: string,
  ): Promise<string> {
    let lastError: unknown;
    for (const modelName of models) {
      for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
        try {
          const result = await this.getClient().models.generateContent({
            model: modelName,
            contents: buildContents() as any,
          });
          this.logger.log(
            `Gemini [${context}] OK with ${modelName} (attempt ${attempt})`,
          );
          return result.text ?? '';
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          lastError = error;
          if (isBusyError(msg) && attempt < MAX_RETRIES) {
            this.logger.warn(
              `Gemini [${context}] ${modelName} saturado, reintento ${attempt}/${MAX_RETRIES} en ${RETRY_DELAY_MS}ms...`,
            );
            await new Promise((r) => setTimeout(r, RETRY_DELAY_MS));
          } else {
            // 404 (la key no tiene ese modelo), saturado tras reintentar u otro error
            this.logger.warn(
              `Gemini [${context}] ${modelName} no disponible (${msg.slice(0, 120)}), probando siguiente...`,
            );
            break;
          }
        }
      }
    }

    // Último recurso para texto: Groq (gratis). Las imágenes no pasan por acá.
    const contents = buildContents();
    const onlyText =
      typeof contents === 'string' || contents.every((p) => !p.inlineData);
    const groqKey = this.configService.get<string>('GROQ_API_KEY');
    if (onlyText && groqKey) {
      const prompt =
        typeof contents === 'string'
          ? contents
          : contents.map((p) => p.text ?? '').join('\n');
      try {
        const text = await this.generateWithGroq(prompt, groqKey);
        this.logger.log(`Groq [${context}] OK (respaldo de Gemini)`);
        return text;
      } catch (error) {
        lastError = error;
        this.logger.warn(
          `Groq [${context}] falló: ${error instanceof Error ? error.message : error}`,
        );
      }
    }
    this.handleGeminiError(lastError, context);
  }

  private async generateWithGroq(
    prompt: string,
    apiKey: string,
  ): Promise<string> {
    const res = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.7,
      }),
      signal: AbortSignal.timeout(30000),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = (await res.json()) as {
      choices?: { message?: { content?: string } }[];
    };
    const text = data.choices?.[0]?.message?.content;
    if (!text) throw new Error('respuesta vacía');
    return text;
  }

  async generateRecipe(input: GenerateRecipeInput): Promise<GeneratedRecipe> {
    const prompt = this.buildRecipePrompt(input);
    const text = await this.generateWithFallback(
      TEXT_MODELS,
      () => [{ text: prompt }],
      'generateRecipe',
    );

    try {
      return extractJson<GeneratedRecipe>(text!);
    } catch {
      this.logger.error(`No se pudo parsear la receta generada: ${text!}`);
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado. Probá de nuevo.',
      );
    }
  }

  async generateDailyMealPlan(
    input: GenerateDailyMealPlanInput,
  ): Promise<GeneratedDailyMealPlan> {
    const prompt = this.buildDailyMealPlanPrompt(input);
    const text = await this.generateWithFallback(
      TEXT_MODELS,
      () => [{ text: prompt }],
      'generateDailyMealPlan',
    );

    try {
      return extractJson<GeneratedDailyMealPlan>(text!);
    } catch {
      this.logger.error(`No se pudo parsear el plan diario generado: ${text!}`);
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado al generar el plan.',
      );
    }
  }

  async detectIngredients(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<DetectedIngredient[]> {
    const prompt = this.buildDetectionPrompt();
    const parts = [
      { text: prompt },
      { inlineData: { data: imageBuffer.toString('base64'), mimeType } },
    ];
    const text = await this.generateWithFallback(
      VISION_MODELS,
      () => parts,
      'detectIngredients',
    );

    try {
      return extractJson<DetectedIngredient[]>(text!);
    } catch {
      this.logger.error(
        `No se pudo parsear la detección de ingredientes: ${text!}`,
      );
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado al analizar la imagen.',
      );
    }
  }

  async detectReceiptItems(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<DetectedReceiptItem[]> {
    const prompt = this.buildReceiptPrompt();
    const parts = [
      { text: prompt },
      { inlineData: { data: imageBuffer.toString('base64'), mimeType } },
    ];
    const text = await this.generateWithFallback(
      VISION_MODELS,
      () => parts,
      'detectReceiptItems',
    );

    try {
      return extractJson<DetectedReceiptItem[]>(text!);
    } catch {
      this.logger.error(`No se pudo parsear el ticket de compra: ${text!}`);
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado al analizar el ticket.',
      );
    }
  }

  async analyzeMealPhoto(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<MealAnalysis> {
    const prompt = this.buildMealAnalysisPrompt();
    const parts = [
      { text: prompt },
      { inlineData: { data: imageBuffer.toString('base64'), mimeType } },
    ];
    const text = await this.generateWithFallback(
      VISION_MODELS,
      () => parts,
      'analyzeMealPhoto',
    );

    try {
      return extractJson<MealAnalysis>(text!);
    } catch {
      this.logger.error(`No se pudo parsear el análisis nutricional: ${text!}`);
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado al analizar el plato.',
      );
    }
  }

  async parseIngredientsFromText(text: string): Promise<DetectedIngredient[]> {
    const prompt = this.buildVoiceInventoryPrompt(text);
    const responseText = await this.generateWithFallback(
      TEXT_MODELS,
      () => [{ text: prompt }],
      'parseIngredientsFromText',
    );

    try {
      return extractJson<DetectedIngredient[]>(responseText!);
    } catch {
      this.logger.error(
        `No se pudo parsear los ingredientes dictados: ${responseText!}`,
      );
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado al interpretar el dictado.',
      );
    }
  }

  async getHealthAdvice(input: HealthAdviceInput): Promise<HealthAdvice> {
    const prompt = this.buildHealthAdvicePrompt(input);
    const text = await this.generateWithFallback(
      TEXT_MODELS,
      () => [{ text: prompt }],
      'getHealthAdvice',
    );

    try {
      return extractJson<HealthAdvice>(text!);
    } catch {
      this.logger.error(`No se pudo parsear los consejos de salud: ${text!}`);
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado al generar los consejos.',
      );
    }
  }

  private buildHealthAdvicePrompt(input: HealthAdviceInput): string {
    const { dietTags, allergies, healthNotes, goal } = input;
    const lines = [
      'Sos un nutricionista. Dale a un usuario de una app de recetas entre 5 y 8 consejos',
      'cortos, prácticos y específicos sobre alimentación, pensados para su situación particular.',
      'Cada consejo debe ser una frase accionable de una sola oración (no un párrafo largo).',
      'No repitas la condición del usuario en cada consejo, andá directo a la recomendación.',
      '',
    ];
    if (healthNotes) {
      lines.push(
        `Condición o necesidad especial indicada por el usuario: "${healthNotes}".`,
      );
    }
    if (dietTags.length) {
      lines.push(`Preferencias/etiquetas dietarias: ${dietTags.join(', ')}.`);
    }
    if (allergies.length) {
      lines.push(`Alergias o intolerancias: ${allergies.join(', ')}.`);
    }
    if (goal) {
      lines.push(`Objetivo general: ${goal}.`);
    }
    if (!healthNotes && !dietTags.length && !allergies.length) {
      lines.push(
        'El usuario no cargó ninguna condición particular: dale consejos generales de alimentación saludable.',
      );
    }
    lines.push(
      '',
      'IMPORTANTE: aclará que estos consejos son generales y no reemplazan a un profesional de la salud.',
      'Incluí esa aclaración como el último elemento del array de consejos, no antes.',
      '',
      'Respondé ÚNICAMENTE con un JSON con esta forma exacta, sin texto adicional ni markdown:',
      '{"tips": ["consejo 1", "consejo 2", "..."]}',
    );
    return lines.join('\n');
  }

  private buildDailyMealPlanPrompt(input: GenerateDailyMealPlanInput): string {
    const {
      mealTypes,
      availableIngredients,
      allergies,
      dietTags,
      healthNotes,
      goal,
      avoidTitles,
    } = input;
    const mealTypeLabels: Record<MealType, string> = {
      [MealType.BREAKFAST]: 'breakfast (desayuno)',
      [MealType.MID_MORNING]: 'mid_morning (colación de media mañana)',
      [MealType.LUNCH]: 'lunch (almuerzo)',
      [MealType.POST_WORKOUT]: 'post_workout (colación post-entreno)',
      [MealType.SNACK]: 'snack (merienda)',
      [MealType.DINNER]: 'dinner (cena)',
    };
    const lines = [
      'Sos un chef profesional y nutricionista armando UN DÍA completo de un plan de comidas.',
      `Generá exactamente estas ${mealTypes.length} comidas para el día, coherentes entre sí:`,
      ...mealTypes.map((mt) => `- ${mealTypeLabels[mt]}`),
      '',
      'Variá las fuentes de proteína y los ingredientes principales entre las comidas del mismo día',
      '(no repitas el mismo plato ni la misma proteína dos veces en el día).',
      '',
      `Ingredientes disponibles: ${availableIngredients.join(', ') || 'ninguno en particular'} (podés asumir sal, aceite, agua y condimentos básicos aunque no estén listados).`,
    ];
    if (allergies.length) {
      lines.push(
        `RESTRICCIÓN OBLIGATORIA: nunca uses estos ingredientes ni derivados (alergias/intolerancias del usuario): ${allergies.join(', ')}.`,
      );
    }
    if (dietTags.length) {
      lines.push(
        `Debe cumplir con estas dietas/etiquetas: ${dietTags.join(', ')}.`,
      );
    }
    if (healthNotes) {
      lines.push(
        `Condición de salud / necesidad especial del usuario: "${healthNotes}".`,
      );
    }
    if (goal) {
      lines.push(`Objetivo general del usuario: ${goal}.`);
    }
    if (avoidTitles.length) {
      lines.push(
        `No repitas estos platos, ya se usaron otros días de esta semana: ${avoidTitles.join(', ')}.`,
      );
    }
    lines.push(
      '',
      'Respondé ÚNICAMENTE con un JSON válido (sin texto adicional, sin markdown) con esta forma exacta:',
      `{
  "meals": [
    {
      "mealType": "breakfast" | "mid_morning" | "lunch" | "post_workout" | "snack" | "dinner",
      "recipe": {
        "title": string,
        "description": string,
        "instructions": [{ "order": number, "instruction": string }],
        "servings": number,
        "prepTimeMinutes": number,
        "difficulty": "easy" | "medium" | "hard",
        "estimatedCostTotal": number,
        "dietTags": string[],
        "ingredients": [{ "name": string, "quantity": number, "unit": string, "notes": string | null }],
        "nutrition": { "calories": number, "proteinG": number, "fatG": number, "carbsG": number, "fiberG": number, "sugarG": number, "sodiumMg": number }
      }
    }
  ]
}`,
      `El array "meals" debe tener exactamente ${mealTypes.length} elementos, uno por cada comida pedida arriba, cada uno con el "mealType" correspondiente.`,
      DIET_TAGS_RULE,
    );
    return lines.join('\n');
  }

  private buildRecipePrompt(input: GenerateRecipeInput): string {
    const { availableIngredients, allergies, preferences } = input;
    const lines = [
      'Sos un chef profesional y nutricionista. Creá UNA receta ORIGINAL y realista usando',
      'preferentemente los ingredientes disponibles listados (podés asumir sal, aceite, agua y condimentos básicos aunque no estén listados).',
      '',
      `Ingredientes disponibles: ${availableIngredients.join(', ') || 'ninguno en particular'}.`,
    ];
    if (allergies.length) {
      lines.push(
        `RESTRICCIÓN OBLIGATORIA: nunca uses estos ingredientes ni derivados (alergias/intolerancias del usuario): ${allergies.join(', ')}.`,
      );
    }
    if (preferences?.dietTags?.length) {
      lines.push(
        `Debe cumplir con estas dietas/etiquetas: ${preferences.dietTags.join(', ')}.`,
      );
    }
    if (preferences?.maxPrepTimeMinutes) {
      lines.push(
        `Tiempo total de preparación máximo: ${preferences.maxPrepTimeMinutes} minutos.`,
      );
    }
    if (preferences?.budget) {
      lines.push(`Presupuesto: ${preferences.budget}.`);
    }
    if (preferences?.servings) {
      lines.push(`Cantidad de porciones: ${preferences.servings}.`);
    }
    if (preferences?.dislikedIngredients?.length) {
      lines.push(
        `Evitá estos ingredientes que no le gustan al usuario: ${preferences.dislikedIngredients.join(', ')}.`,
      );
    }
    if (preferences?.freeTextRequest) {
      lines.push(
        `Pedido adicional del usuario en sus propias palabras: "${preferences.freeTextRequest}"`,
      );
    }
    lines.push(
      '',
      'Respondé ÚNICAMENTE con un JSON válido (sin texto adicional, sin markdown) con esta forma exacta:',
      `{
  "title": string,
  "description": string,
  "instructions": [{ "order": number, "instruction": string }],
  "servings": number,
  "prepTimeMinutes": number,
  "difficulty": "easy" | "medium" | "hard",
  "estimatedCostTotal": number,
  "dietTags": string[],
  "ingredients": [{ "name": string, "quantity": number, "unit": string, "notes": string | null }],
  "nutrition": { "calories": number, "proteinG": number, "fatG": number, "carbsG": number, "fiberG": number, "sugarG": number, "sodiumMg": number }
}`,
      DIET_TAGS_RULE,
    );
    return lines.join('\n');
  }

  private buildDetectionPrompt(): string {
    return [
      'Sos un sistema de visión artificial especializado en alimentos. Analizá la imagen (heladera, alacena, mesa o alimentos sueltos)',
      'e identificá cada alimento o ingrediente visible.',
      '',
      'Respondé ÚNICAMENTE con un JSON válido (sin texto adicional, sin markdown), un array con esta forma exacta:',
      `[{ "name": string, "approxQuantity": number, "unit": string, "state": "fresh" | "frozen" | "opened" | "expired" | "unknown", "confidence": number }]`,
      'confidence es un número entre 0 y 1. Si no estás seguro del alimento, igual incluilo con confidence bajo.',
    ].join('\n');
  }

  private buildReceiptPrompt(): string {
    return [
      'Sos un sistema de visión artificial especializado en leer tickets de compra de supermercado o verdulería',
      '(mayormente de Argentina). Analizá la imagen del ticket e identificá cada producto alimenticio comprado,',
      'ignorando productos de limpieza, bazar u otros no comestibles, y también el total, subtotales o descuentos.',
      '',
      'Para cada producto, normalizá el nombre a un ingrediente genérico y simple en español',
      '(ej. "PECHUGA POLLO KG x1.250" -> "Pollo (pechuga)"). Interpretá el peso o cantidad y su unidad',
      '("kg", "g", "l", "ml" o "unidad" si se vendió por bulto/unidad), el precio unitario y el precio total pagado',
      'por ese renglón (si el ticket solo trae un precio, usalo para ambos campos).',
      '',
      'Respondé ÚNICAMENTE con un JSON válido (sin texto adicional, sin markdown), un array con esta forma exacta:',
      `[{ "name": string, "quantity": number, "unit": "g" | "kg" | "ml" | "l" | "unidad", "unitPrice": number, "totalPrice": number }]`,
      'Si no podés leer algún campo con certeza, estimalo lo mejor posible; no inventes productos que no estén en el ticket.',
    ].join('\n');
  }

  private buildVoiceInventoryPrompt(text: string): string {
    return [
      'Sos un asistente que interpreta lo que un usuario dictó por voz sobre los alimentos que tiene para agregar a su',
      'inventario de cocina. El texto puede venir con errores de transcripción o de forma coloquial.',
      '',
      `Texto dictado: "${text}"`,
      '',
      'Identificá cada alimento mencionado con su cantidad aproximada y unidad ("g", "kg", "ml", "l" o "unidad" si no',
      'se especifica peso/volumen, ej. "una docena de huevos" -> 12 unidad).',
      '',
      'Respondé ÚNICAMENTE con un JSON válido (sin texto adicional, sin markdown), un array con esta forma exacta:',
      `[{ "name": string, "approxQuantity": number, "unit": string, "state": "fresh" | "frozen" | "opened" | "expired" | "unknown", "confidence": number }]`,
      'Usá "fresh" como estado por defecto salvo que el texto indique otra cosa. confidence es un número entre 0 y 1.',
    ].join('\n');
  }

  private buildMealAnalysisPrompt(): string {
    return [
      'Sos un nutricionista experto en estimar valores nutricionales a partir de fotos de platos de comida ya preparados/cocinados.',
      'Analizá la imagen (un plato, un bowl, una porción sobre la mesa, etc.), identificá el plato en su conjunto y cada',
      'componente visible, y estimá el tamaño de la porción observando referencias visuales típicas (tamaño del plato, cubiertos, etc.).',
      '',
      'Respondé ÚNICAMENTE con un JSON válido (sin texto adicional, sin markdown) con esta forma exacta:',
      `{
  "dishName": string,
  "description": string,
  "estimatedServingGrams": number,
  "confidence": number,
  "items": [{ "name": string, "approxGrams": number }],
  "nutrition": { "calories": number, "proteinG": number, "fatG": number, "carbsG": number, "fiberG": number, "sugarG": number, "sodiumMg": number }
}`,
      'confidence es un número entre 0 y 1 que indica qué tan seguro estás de la identificación y la estimación.',
      'Si la imagen no muestra comida, igual respondé con el JSON, usando dishName "No se detectó comida" y confidence 0.',
    ].join('\n');
  }

  async fetchIngredientsNutrition(
    ingredients: { id: string; name: string }[],
  ): Promise<IngredientNutritionData[]> {
    if (ingredients.length === 0) return [];
    const prompt = `Dado los siguientes ingredientes de cocina, devolvé un JSON array con los valores nutricionales aproximados POR CADA 100 gramos (o 100ml para líquidos).
Para cada ingrediente incluí: id, caloriesPer100g, proteinPer100g, fatPer100g, carbsPer100g, fiberPer100g.
Usá valores nutricionales estándar. Devolvé SOLO el JSON array, sin texto extra.

Ingredientes:
${ingredients.map((i) => `- id: "${i.id}", nombre: "${i.name}"`).join('\n')}

Formato:
[{"id":"...","caloriesPer100g":200,"proteinPer100g":15,"fatPer100g":8,"carbsPer100g":5,"fiberPer100g":0}]`;

    try {
      const text = await this.generateWithFallback(
        TEXT_MODELS,
        () => [{ text: prompt }],
        'fetchIngredientsNutrition',
      );
      return JSON.parse(
        text.match(/\[[\s\S]*\]/)?.[0] ?? '[]',
      ) as IngredientNutritionData[];
    } catch {
      return [];
    }
  }
}
