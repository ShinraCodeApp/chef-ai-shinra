import { Inject, Injectable } from '@nestjs/common';
import {
  AI_PROVIDER,
  AiProvider,
  DetectedIngredient,
  DetectedReceiptItem,
  GeneratedRecipe,
  HealthAdvice,
  MealAnalysis,
} from './ai-provider.interface';
import { GenerateRecipeDto } from './dto/generate-recipe.dto';
import { UsersService } from '../users/users.service';
import { RecipesService } from '../recipes/recipes.service';
import { IngredientsService } from '../ingredients/ingredients.service';
import { StorageService } from '../storage/storage.service';
import { Recipe } from '../recipes/entities/recipe.entity';
import {
  IngredientCategory,
  IngredientUnit,
  MealType,
  RecipeDifficulty,
} from '../../common/enums';

export interface DetectedIngredientWithCatalog extends DetectedIngredient {
  ingredientId: string;
}

export interface DetectedReceiptItemWithCatalog extends DetectedReceiptItem {
  ingredientId: string;
}

@Injectable()
export class AiService {
  constructor(
    @Inject(AI_PROVIDER) private readonly aiProvider: AiProvider,
    private readonly usersService: UsersService,
    private readonly recipesService: RecipesService,
    private readonly ingredientsService: IngredientsService,
    private readonly storageService: StorageService,
  ) {}

  async generateRecipeForUser(
    userId: string,
    dto: GenerateRecipeDto,
  ): Promise<Recipe> {
    await this.usersService.checkAndConsumeAiGeneration(userId);
    const user = await this.usersService.findById(userId);

    const generated = await this.aiProvider.generateRecipe({
      availableIngredients: dto.availableIngredients,
      allergies: user.allergies ?? [],
      preferences: {
        dietTags: dto.dietTags ?? user.dietPreferences,
        maxPrepTimeMinutes: dto.maxPrepTimeMinutes,
        budget: dto.budget,
        servings: dto.servings,
        dislikedIngredients: dto.dislikedIngredients,
        freeTextRequest: dto.freeTextRequest,
      },
    });

    return this.persistGeneratedRecipe(generated, userId);
  }

  /**
   * Genera un día completo de comidas (todas las mealTypes pedidas) en UNA sola
   * llamada a la IA, en vez de una llamada por comida — mucho más rápido y le da
   * a la IA contexto para variar entre las comidas del mismo día.
   */
  async generateDailyMealPlanForUser(
    userId: string,
    params: {
      availableIngredients: string[];
      mealTypes: MealType[];
      dietTags?: string[];
      avoidTitles: string[];
    },
  ): Promise<{ mealType: MealType; recipe: Recipe }[]> {
    const user = await this.usersService.findById(userId);

    const generated = await this.aiProvider.generateDailyMealPlan({
      mealTypes: params.mealTypes,
      availableIngredients: params.availableIngredients,
      allergies: user.allergies ?? [],
      dietTags: params.dietTags ?? user.dietPreferences ?? [],
      healthNotes: user.healthNotes,
      goal: user.goal,
      avoidTitles: params.avoidTitles,
    });

    return Promise.all(
      generated.meals.map(async (meal) => ({
        mealType: meal.mealType,
        recipe: await this.persistGeneratedRecipe(meal.recipe, userId),
      })),
    );
  }

  private async persistGeneratedRecipe(
    generated: GeneratedRecipe,
    userId: string,
  ): Promise<Recipe> {
    const ingredients = await Promise.all(
      generated.ingredients.map(async (ing) => {
        const ingredient = await this.ingredientsService.findOrCreateByName(
          ing.name,
          {
            category: IngredientCategory.OTROS,
            unit: this.parseUnit(ing.unit),
          },
        );
        return {
          ingredientId: ingredient.id,
          quantity: ing.quantity,
          unit: this.parseUnit(ing.unit),
          notes: ing.notes,
        };
      }),
    );

    return this.recipesService.create(
      {
        title: generated.title,
        description: generated.description,
        instructions: generated.instructions,
        servings: generated.servings,
        prepTimeMinutes: generated.prepTimeMinutes,
        difficulty: generated.difficulty as RecipeDifficulty,
        estimatedCostTotal: generated.estimatedCostTotal,
        dietTags: generated.dietTags,
        ingredients,
      },
      {
        createdByUserId: userId,
        isAiGenerated: true,
        nutrition: generated.nutrition,
      },
    );
  }

  async scanImageForIngredients(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<DetectedIngredientWithCatalog[]> {
    const detected = await this.aiProvider.detectIngredients(
      imageBuffer,
      mimeType,
    );

    if (this.storageService.isConfigured()) {
      // se guarda la imagen escaneada para trazabilidad, sin bloquear la respuesta si falla
      this.storageService
        .upload(imageBuffer, mimeType, 'inventory-scans')
        .catch(() => undefined);
    }

    return Promise.all(
      detected.map(async (item) => {
        const ingredient = await this.ingredientsService.findOrCreateByName(
          item.name,
          {
            category: IngredientCategory.OTROS,
            unit: this.parseUnit(item.unit),
          },
        );
        return { ...item, ingredientId: ingredient.id };
      }),
    );
  }

  async scanReceiptForItems(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<DetectedReceiptItemWithCatalog[]> {
    const detected = await this.aiProvider.detectReceiptItems(
      imageBuffer,
      mimeType,
    );

    if (this.storageService.isConfigured()) {
      // se guarda el ticket escaneado para trazabilidad, sin bloquear la respuesta si falla
      this.storageService
        .upload(imageBuffer, mimeType, 'receipt-scans')
        .catch(() => undefined);
    }

    return Promise.all(
      detected.map(async (item) => {
        const ingredient = await this.ingredientsService.findOrCreateByName(
          item.name,
          {
            category: IngredientCategory.OTROS,
            unit: this.parseUnit(item.unit),
          },
        );
        return { ...item, ingredientId: ingredient.id };
      }),
    );
  }

  async analyzeMealPhoto(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<MealAnalysis> {
    const analysis = await this.aiProvider.analyzeMealPhoto(
      imageBuffer,
      mimeType,
    );

    if (this.storageService.isConfigured()) {
      // se guarda la foto del plato para trazabilidad, sin bloquear la respuesta si falla
      this.storageService
        .upload(imageBuffer, mimeType, 'meal-scans')
        .catch(() => undefined);
    }

    return analysis;
  }

  async parseVoiceInventory(text: string): Promise<DetectedIngredientWithCatalog[]> {
    const detected = await this.aiProvider.parseIngredientsFromText(text);

    return Promise.all(
      detected.map(async (item) => {
        const ingredient = await this.ingredientsService.findOrCreateByName(
          item.name,
          {
            category: IngredientCategory.OTROS,
            unit: this.parseUnit(item.unit),
          },
        );
        return { ...item, ingredientId: ingredient.id };
      }),
    );
  }

  async getHealthAdviceForUser(userId: string): Promise<HealthAdvice> {
    const user = await this.usersService.findById(userId);
    return this.aiProvider.getHealthAdvice({
      dietTags: user.dietPreferences ?? [],
      allergies: user.allergies ?? [],
      healthNotes: user.healthNotes,
      goal: user.goal,
    });
  }

  private parseUnit(unit: string): IngredientUnit {
    const normalized = unit.trim().toLowerCase();
    const match = Object.values(IngredientUnit).find(
      (value) => value === normalized,
    );
    return match ?? IngredientUnit.UNIT;
  }
}
