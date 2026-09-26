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
  GenerateRecipeInput,
  GeneratedRecipe,
  HealthAdvice,
  HealthAdviceInput,
  MealAnalysis,
} from '../ai-provider.interface';
import { extractJson } from '../utils/extract-json';

// gemini-2.5-flash fue discontinuado para cuentas nuevas (jul. 2026). gemini-3.6-flash
// (la generación "estable" recomendada) devolvía 503 "high demand" de forma persistente
// al momento de escribir esto — gemini-3-flash-preview es multimodal (texto + visión) y
// respondía con normalidad. Si 3.6-flash vuelve a estar disponible, se puede volver a él.
const TEXT_MODEL = 'gemini-3-flash-preview';
const VISION_MODEL = 'gemini-3-flash-preview';

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

  async generateRecipe(input: GenerateRecipeInput): Promise<GeneratedRecipe> {
    const model = this.getClient().getGenerativeModel({ model: TEXT_MODEL });
    const prompt = this.buildRecipePrompt(input);

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    try {
      return extractJson<GeneratedRecipe>(text);
    } catch (error) {
      this.logger.error(`No se pudo parsear la receta generada: ${text}`);
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado. Probá de nuevo.',
      );
    }
  }

  async detectIngredients(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<DetectedIngredient[]> {
    const model = this.getClient().getGenerativeModel({ model: VISION_MODEL });
    const prompt = this.buildDetectionPrompt();

    const result = await model.generateContent([
      { text: prompt },
      { inlineData: { data: imageBuffer.toString('base64'), mimeType } },
    ]);
    const text = result.response.text();

    try {
      return extractJson<DetectedIngredient[]>(text);
    } catch (error) {
      this.logger.error(
        `No se pudo parsear la detección de ingredientes: ${text}`,
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
    const model = this.getClient().getGenerativeModel({ model: VISION_MODEL });
    const prompt = this.buildReceiptPrompt();

    const result = await model.generateContent([
      { text: prompt },
      { inlineData: { data: imageBuffer.toString('base64'), mimeType } },
    ]);
    const text = result.response.text();

    try {
      return extractJson<DetectedReceiptItem[]>(text);
    } catch (error) {
      this.logger.error(`No se pudo parsear el ticket de compra: ${text}`);
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado al analizar el ticket.',
      );
    }
  }

  async analyzeMealPhoto(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<MealAnalysis> {
    const model = this.getClient().getGenerativeModel({ model: VISION_MODEL });
    const prompt = this.buildMealAnalysisPrompt();

    const result = await model.generateContent([
      { text: prompt },
      { inlineData: { data: imageBuffer.toString('base64'), mimeType } },
    ]);
    const text = result.response.text();

    try {
      return extractJson<MealAnalysis>(text);
    } catch (error) {
      this.logger.error(`No se pudo parsear el análisis nutricional: ${text}`);
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado al analizar el plato.',
      );
    }
  }

  async parseIngredientsFromText(text: string): Promise<DetectedIngredient[]> {
    const model = this.getClient().getGenerativeModel({ model: TEXT_MODEL });
    const prompt = this.buildVoiceInventoryPrompt(text);

    const result = await model.generateContent(prompt);
    const responseText = result.response.text();

    try {
      return extractJson<DetectedIngredient[]>(responseText);
    } catch (error) {
      this.logger.error(
        `No se pudo parsear los ingredientes dictados: ${responseText}`,
      );
      throw new InternalServerErrorException(
        'La IA devolvió una respuesta con un formato inesperado al interpretar el dictado.',
      );
    }
  }

  async getHealthAdvice(input: HealthAdviceInput): Promise<HealthAdvice> {
    const model = this.getClient().getGenerativeModel({ model: TEXT_MODEL });
    const prompt = this.buildHealthAdvicePrompt(input);

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    try {
      return extractJson<HealthAdvice>(text);
    } catch (error) {
      this.logger.error(`No se pudo parsear los consejos de salud: ${text}`);
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
