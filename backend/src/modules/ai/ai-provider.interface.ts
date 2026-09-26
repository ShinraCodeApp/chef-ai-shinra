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

export interface DetectedReceiptItem {
  name: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  totalPrice: number;
}

export interface MealAnalysisNutrition {
  calories: number;
  proteinG: number;
  fatG: number;
  carbsG: number;
  fiberG: number;
  sugarG: number;
  sodiumMg: number;
}

export interface MealAnalysisItem {
  name: string;
  approxGrams: number;
}

export interface MealAnalysis {
  dishName: string;
  description: string;
  estimatedServingGrams: number;
  confidence: number;
  items: MealAnalysisItem[];
  nutrition: MealAnalysisNutrition;
}

export interface HealthAdviceInput {
  dietTags: string[];
  allergies: string[];
  healthNotes?: string | null;
  goal?: string | null;
}

export interface HealthAdvice {
  tips: string[];
}

export const AI_PROVIDER = Symbol('AI_PROVIDER');

export interface AiProvider {
  generateRecipe(input: GenerateRecipeInput): Promise<GeneratedRecipe>;
  detectIngredients(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<DetectedIngredient[]>;
  detectReceiptItems(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<DetectedReceiptItem[]>;
  analyzeMealPhoto(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<MealAnalysis>;
  parseIngredientsFromText(text: string): Promise<DetectedIngredient[]>;
  getHealthAdvice(input: HealthAdviceInput): Promise<HealthAdvice>;
}
