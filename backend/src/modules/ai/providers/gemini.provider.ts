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
  GenerateRecipeInput,
  GeneratedRecipe,
} from '../ai-provider.interface';
import { extractJson } from '../utils/extract-json';

// gemini-2.5-flash fue discontinuado para cuentas nuevas (jul. 2026); se usa la
// generación 3.x vigente. gemini-3.6-flash es multimodal (texto + visión).
const TEXT_MODEL = 'gemini-3.6-flash';
const VISION_MODEL = 'gemini-3.6-flash';

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
}
