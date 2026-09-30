import {
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import {
  AiProvider,
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

// gemini-2.5-flash fue discontinuado para cuentas nuevas (jul. 2026). gemini-3.6-flash
// (la generación "estable" recomendada) devolvía 503 "high demand" de forma persistente
// al momento de escribir esto — gemini-3-flash-preview es multimodal (texto + visión) y
// respondía con normalidad. Si 3.6-flash vuelve a estar disponible, se puede volver a él.
// gemini-3.8-flash solo existe en v1beta pero tiene alta demanda (503).
// gemini-1.5-flash existe en v1 y es el fallback estable.
const TEXT_MODELS = ['gemini-3.8-flash', 'gemini-1.5-flash'];
const VISION_MODELS = ['gemini-3.8-flash', 'gemini-1.5-flash'];
const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 2000;

@Injectable()
export class GeminiProvider implements AiProvider {
  private readonly logger = new Logger(GeminiProvider.name);
  private readonly client: GoogleGenerativeAI | null;

  constructor(private readonly configService: ConfigService) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (apiKey) {
      this.client = new GoogleGenerativeAI(apiKey);
    } else {
      this.client = null;
      this.logger.warn(
        'GEMINI_API_KEY no configurada — los endpoints de IA fallarán hasta que se configure.',
      );
    }
  }

  private getClient(): GoogleGenerativeAI {
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
    throw new InternalServerErrorException(`IA no disponible: ${msg}`);
  }

  // gemini-3.8-flash solo existe en v1beta; gemini-1.5-flash requiere v1
  private getApiVersion(modelName: string): string {
    return modelName.startsWith('gemini-1.') ? 'v1' : 'v1beta';
  }

  private async generateWithFallback(
    models: string[],
    buildParts: (model: string) => string | Array<{ text?: string; inlineData?: { data: string; mimeType: string } }>,
    context: string,
  ): Promise<string> {
    let lastError: unknown;
    for (const modelName of models) {
      const apiVersion = this.getApiVersion(modelName);
      for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
        try {
          const model = this.getClient().getGenerativeModel(
            { model: modelName },
            { apiVersion },
          );
          const result = await model.generateContent(buildParts(modelName) as any);
          this.logger.log(`Gemini [${context}] OK with ${modelName} (${apiVersion}, attempt ${attempt})`);
          return result.response.text();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          lastError = error;
          const is503 = msg.includes('503');
          const is404 = msg.includes('404');
          if (is503 && attempt < MAX_RETRIES) {
            this.logger.warn(`Gemini [${context}] ${modelName} sobrecargado, reintento ${attempt}/${MAX_RETRIES} en ${RETRY_DELAY_MS}ms...`);
            await new Promise((r) => setTimeout(r, RETRY_DELAY_MS));
          } else if (is404 || is503) {
            this.logger.warn(`Gemini [${context}] ${modelName} no disponible, probando siguiente modelo...`);
            break;
          } else {
            this.logger.warn(`Gemini [${context}] ${modelName} error: ${msg}`);
            break;
          }
        }
      }
    }
    this.handleGeminiError(lastError, context);
  }

  async generateRecipe(input: GenerateRecipeInput): Promise<GeneratedRecipe> {
    const prompt = this.buildRecipePrompt(input);
    const text = await this.generateWithFallback(TEXT_MODELS, () => prompt, 'generateRecipe');

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
    const text = await this.generateWithFallback(TEXT_MODELS, () => prompt, 'generateDailyMealPlan');

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
    const text = await this.generateWithFallback(VISION_MODELS, () => parts, 'detectIngredients');

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
    const text = await this.generateWithFallback(VISION_MODELS, () => parts, 'detectReceiptItems');

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
    const text = await this.generateWithFallback(VISION_MODELS, () => parts, 'analyzeMealPhoto');

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
    const responseText = await this.generateWithFallback(TEXT_MODELS, () => prompt, 'parseIngredientsFromText');

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
    const text = await this.generateWithFallback(TEXT_MODELS, () => prompt, 'getHealthAdvice');

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
      lines.push(`Condición o necesidad especial indicada por el usuario: "${healthNotes}".`);
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
      lines.push(`Debe cumplir con estas dietas/etiquetas: ${dietTags.join(', ')}.`);
    }
    if (healthNotes) {
      lines.push(`Condición de salud / necesidad especial del usuario: "${healthNotes}".`);
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
}
