export interface GenerateRecipePreferences {
  dietTags?: string[];
  maxPrepTimeMinutes?: number;
  budget?: 'low' | 'medium' | 'high';
  servings?: number;
  dislikedIngredients?: string[];
  freeTextRequest?: string;
}

export interface GenerateRecipeInput {
  availableIngredients: string[];
  allergies: string[];
  preferences?: GenerateRecipePreferences;
}

export interface GeneratedRecipeIngredient {
  name: string;
  quantity: number;
  unit: string;
  notes?: string;
}

export interface GeneratedRecipeStep {
  order: number;
  instruction: string;
}

export interface GeneratedRecipeNutrition {
  calories: number;
  proteinG: number;
  fatG: number;
  carbsG: number;
  fiberG: number;
  sugarG: number;
  sodiumMg: number;
}

export interface GeneratedRecipe {
  title: string;
  description: string;
  instructions: GeneratedRecipeStep[];
  servings: number;
  prepTimeMinutes: number;
  difficulty: 'easy' | 'medium' | 'hard';
  estimatedCostTotal: number;
  dietTags: string[];
  ingredients: GeneratedRecipeIngredient[];
  nutrition: GeneratedRecipeNutrition;
}

export interface DetectedIngredient {
  name: string;
  approxQuantity: number;
  unit: string;
  state: 'fresh' | 'frozen' | 'opened' | 'expired' | 'unknown';
  confidence: number;
}

export const AI_PROVIDER = Symbol('AI_PROVIDER');

export interface AiProvider {
  generateRecipe(input: GenerateRecipeInput): Promise<GeneratedRecipe>;
  detectIngredients(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<DetectedIngredient[]>;
}
