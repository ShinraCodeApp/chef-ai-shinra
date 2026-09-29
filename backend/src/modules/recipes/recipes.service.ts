import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Recipe, RecipeNutrition } from './entities/recipe.entity';
import { Favorite } from './entities/favorite.entity';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { QueryRecipesDto } from './dto/query-recipes.dto';
import { InventoryService } from '../inventory/inventory.service';
import {
  paginate,
  PaginatedResult,
} from '../../common/dto/pagination-query.dto';
import { IngredientUnit, UserRole } from '../../common/enums';
import {
  CALCIUM_RICH,
  DAIRY,
  HEART_FRIENDLY,
  HealthConditionKey,
  IRON_RICH,
  SATURATED_FAT,
  searchFilterFor,
} from './search-tags';

const CONDITION_PARAMS = {
  dairy: DAIRY,
  heartFriendly: HEART_FRIENDLY,
  saturatedFat: SATURATED_FAT,
  ironRich: IRON_RICH,
  calciumRich: CALCIUM_RICH,
};

export interface MissingIngredient {
  ingredientId: string;
  name: string;
  quantity: number;
  unit: IngredientUnit;
}

@Injectable()
export class RecipesService {
  constructor(
    @InjectRepository(Recipe)
    private readonly recipesRepository: Repository<Recipe>,
    @InjectRepository(Favorite)
    private readonly favoritesRepository: Repository<Favorite>,
    private readonly inventoryService: InventoryService,
  ) {}

  create(
    dto: CreateRecipeDto,
    options: {
      createdByUserId?: string;
      isAiGenerated?: boolean;
      nutrition?: RecipeNutrition;
    } = {},
  ): Promise<Recipe> {
    const recipe = this.recipesRepository.create({
      title: dto.title,
      description: dto.description,
      instructions: dto.instructions,
      servings: dto.servings,
      prepTimeMinutes: dto.prepTimeMinutes,
      difficulty: dto.difficulty,
      estimatedCostTotal: dto.estimatedCostTotal ?? null,
      imageUrl: dto.imageUrl ?? null,
      dietTags: dto.dietTags ?? [],
      tips: dto.tips ?? null,
      isAiGenerated: options.isAiGenerated ?? false,
      createdByUserId: options.createdByUserId ?? null,
      nutrition: options.nutrition ?? null,
      recipeIngredients: dto.ingredients.map((ing, index) => ({
        ingredientId: ing.ingredientId,
        quantity: ing.quantity,
        unit: ing.unit,
        notes: ing.notes ?? null,
        order: index,
      })),
    });
    return this.recipesRepository.save(recipe);
  }

  async findAll(
    query: QueryRecipesDto,
    userId?: string,
  ): Promise<PaginatedResult<Recipe>> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const qb = this.recipesRepository
      .createQueryBuilder('recipe')
      .orderBy('recipe.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    if (query.search) {
      // Si lo buscado es una etiqueta o una condición de salud ("vegano",
      // "celíaco", "diabetes"...), se devuelven todas las recetas que la cumplan,
      // además de las que lo mencionen en el título.
      const filter = searchFilterFor(query.search);
      const titleMatch = 'recipe.title ILIKE :search';
      const params = { search: `%${query.search}%` };
      if (filter?.kind === 'tag') {
        qb.andWhere(`(${titleMatch} OR :searchTag = ANY(recipe.dietTags))`, {
          ...params,
          searchTag: filter.tag,
        });
      } else if (filter?.kind === 'condition') {
        qb.andWhere(
          `(${titleMatch} OR (${this.conditionSql(filter.condition)}))`,
          { ...params, ...CONDITION_PARAMS },
        );
      } else {
        qb.andWhere(titleMatch, params);
      }
    }
    if (query.dietTag) {
      qb.andWhere(':dietTag = ANY(recipe.dietTags)', {
        dietTag: query.dietTag,
      });
    }
    if (query.ingredient) {
      // match por palabra completa (case-insensitive), no por substring: "pollo" no
      // debe encontrar "Repollo". \y es el ancla de límite de palabra de Postgres.
      const escapedIngredient = query.ingredient.replace(
        /[.*+?^${}()|[\]\\]/g,
        '\\$&',
      );
      qb.andWhere(
        (subQb) => {
          const subQuery = subQb
            .subQuery()
            .select('ri.recipeId')
            .from('recipe_ingredients', 'ri')
            .innerJoin('ingredients', 'ing', 'ing.id = ri."ingredientId"')
            .where(`ing.name ~* ('\\y' || :ingredient || '\\y')`)
            .getQuery();
          return `recipe.id IN ${subQuery}`;
        },
        { ingredient: escapedIngredient },
      );
      // columna auxiliar (no persistida) que indica si el ingrediente buscado es
      // el principal (order = 0) de esa receta, para poder separar los resultados
      // en "ingrediente principal" vs. "también lo contienen" del lado del cliente.
      qb.addSelect((subQb) => {
        return subQb
          .subQuery()
          .select('1')
          .from('recipe_ingredients', 'ri2')
          .innerJoin('ingredients', 'ing2', 'ing2.id = ri2."ingredientId"')
          .where('ri2."recipeId" = recipe.id')
          .andWhere('ri2."order" = 0')
          .andWhere(`ing2.name ~* ('\\y' || :ingredient || '\\y')`)
          .limit(1);
      }, 'is_main_match');
      qb.orderBy('is_main_match', 'DESC', 'NULLS LAST').addOrderBy(
        'recipe.createdAt',
        'DESC',
      );
    }
    if (query.maxPrepTimeMinutes !== undefined) {
      qb.andWhere('recipe.prepTimeMinutes <= :maxPrepTimeMinutes', {
        maxPrepTimeMinutes: query.maxPrepTimeMinutes,
      });
    }

    // Búsqueda multi-ingrediente: filtra recetas que contengan AL MENOS UNO
    // de los ingredientes indicados y ordena por cantidad de matches (más primero).
    const ingredientList = query.ingredients
      ? query.ingredients
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean)
      : [];

    if (ingredientList.length > 0) {
      const escaped = ingredientList.map((ing) =>
        ing.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
      );
      const regexPattern = escaped.map((e) => `\\y${e}\\y`).join('|');
      qb.andWhere(
        (subQb) => {
          const subQuery = subQb
            .subQuery()
            .select('ri.recipeId')
            .from('recipe_ingredients', 'ri')
            .innerJoin('ingredients', 'ing', 'ing.id = ri."ingredientId"')
            .where(`ing.name ~* :multiPattern`)
            .getQuery();
          return `recipe.id IN ${subQuery}`;
        },
        { multiPattern: regexPattern },
      );
      // Columna auxiliar: cuántos de los ingredientes buscados tiene la receta
      qb.addSelect((subQb) => {
        return subQb
          .subQuery()
          .select('COUNT(*)')
          .from('recipe_ingredients', 'rim')
          .innerJoin('ingredients', 'ingm', 'ingm.id = rim."ingredientId"')
          .where('rim."recipeId" = recipe.id')
          .andWhere(`ingm.name ~* :multiPattern`);
      }, 'match_count');
      qb.orderBy('match_count', 'DESC').addOrderBy('recipe.createdAt', 'DESC');
    }

    let items: Recipe[];
    let total: number;
    if (query.ingredient || ingredientList.length > 0) {
      const { entities, raw } = await qb.getRawAndEntities();
      items = entities.map((recipe, index) => {
        if (query.ingredient) {
          recipe.isMainIngredientMatch = raw[index]?.is_main_match != null;
        }
        if (ingredientList.length > 0) {
          recipe.matchCount = Number(raw[index]?.match_count ?? 0);
        }
        return recipe;
      });
      total = await qb.getCount();
    } else {
      [items, total] = await qb.getManyAndCount();
    }

    if (userId && items.length) {
      await this.attachFavoriteFlags(items, userId);
    }
    return paginate(items, total, page, limit);
  }

  /**
   * SQL de cada condición de salud, con los mismos criterios que el detalle de
   * la receta en la app. Usa los parámetros de CONDITION_PARAMS.
   */
  private conditionSql(condition: HealthConditionKey): string {
    const n = (key: string) => `(recipe.nutrition->>'${key}')::float`;
    const hasIngredient = (param: string) =>
      `EXISTS (SELECT 1 FROM recipe_ingredients hri
        INNER JOIN ingredients hing ON hing.id = hri."ingredientId"
        WHERE hri."recipeId" = recipe.id AND hing.name IN (:...${param}))`;
    switch (condition) {
      case 'diabetes':
        return `${n('carbsG')} <= 20 AND ${n('sugarG')} <= 10`;
      case 'hipertension':
        return `${n('sodiumMg')} <= 300`;
      case 'estrenimiento':
        return `${n('fiberG')} >= 6`;
      case 'sobrepeso':
        return `${n('calories')} > 0 AND ${n('calories')} <= 350 AND ${n('proteinG')} >= 15`;
      case 'lactosa':
        return `NOT ${hasIngredient('dairy')}`;
      case 'corazon':
        return `${hasIngredient('heartFriendly')} AND NOT ${hasIngredient('saturatedFat')} AND ${n('fatG')} <= 25`;
      case 'anemia':
        return hasIngredient('ironRich');
      case 'osteoporosis':
        return hasIngredient('calciumRich');
    }
  }

  async findOne(id: string, userId?: string): Promise<Recipe> {
    const recipe = await this.recipesRepository.findOne({
      where: { id },
      relations: { recipeIngredients: true },
    });
    if (!recipe) {
      throw new NotFoundException('Receta no encontrada');
    }
    if (userId) {
      await this.attachFavoriteFlags([recipe], userId);
    }
    return recipe;
  }

  /** Completa `isFavorite` en cada receta en base a los favoritos del usuario, en una sola query. */
  private async attachFavoriteFlags(
    recipes: Recipe[],
    userId: string,
  ): Promise<void> {
    const favorited = await this.favoritesRepository.find({
      where: { userId, recipeId: In(recipes.map((r) => r.id)) },
    });
    const favoritedIds = new Set(favorited.map((f) => f.recipeId));
    for (const recipe of recipes) {
      recipe.isFavorite = favoritedIds.has(recipe.id);
    }
  }

  async update(
    id: string,
    dto: UpdateRecipeDto,
    requester: { userId: string; role: string },
  ): Promise<Recipe> {
    const recipe = await this.findOne(id);
    this.assertCanModify(recipe, requester);
    Object.assign(recipe, dto);
    return this.recipesRepository.save(recipe);
  }

  async remove(
    id: string,
    requester: { userId: string; role: string },
  ): Promise<void> {
    const recipe = await this.findOne(id);
    this.assertCanModify(recipe, requester);
    await this.recipesRepository.remove(recipe);
  }

  /** Solo el creador de la receta o un admin pueden editarla/borrarla. */
  private assertCanModify(
    recipe: Recipe,
    requester: { userId: string; role: string },
  ): void {
    const isOwner = recipe.createdByUserId === requester.userId;
    const isAdmin = requester.role === UserRole.ADMIN;
    if (!isOwner && !isAdmin) {
      throw new ForbiddenException(
        'Solo quien creó la receta (o un admin) puede modificarla',
      );
    }
  }

  /**
   * Marca la receta como cocinada: descuenta del inventario del usuario los ingredientes
   * usados. Devuelve también los ingredientes a sugerir para la lista de compras: los que
   * no se pudieron descontar del todo por no haber suficiente en inventario, y los que
   * sí alcanzaron pero quedaron en 0 (se terminaron con esta receta).
   */
  async cook(
    userId: string,
    id: string,
    servingsMultiplier = 1,
  ): Promise<{ recipe: Recipe; missingIngredients: MissingIngredient[] }> {
    const recipe = await this.findOne(id);
    const missingIngredients: MissingIngredient[] = [];
    for (const recipeIngredient of recipe.recipeIngredients) {
      const neededQuantity = recipeIngredient.quantity * servingsMultiplier;
      const { shortfall, depleted } = await this.inventoryService.consume(
        userId,
        recipeIngredient.ingredientId,
        neededQuantity,
        recipeIngredient.unit,
      );
      if (shortfall > 0) {
        missingIngredients.push({
          ingredientId: recipeIngredient.ingredientId,
          name: recipeIngredient.ingredient.name,
          quantity: shortfall,
          unit: recipeIngredient.unit,
        });
      } else if (depleted) {
        missingIngredients.push({
          ingredientId: recipeIngredient.ingredientId,
          name: recipeIngredient.ingredient.name,
          quantity: neededQuantity,
          unit: recipeIngredient.unit,
        });
      }
    }
    return { recipe, missingIngredients };
  }

  async toggleFavorite(
    userId: string,
    recipeId: string,
  ): Promise<{ favorited: boolean }> {
    await this.findOne(recipeId);
    const existing = await this.favoritesRepository.findOne({
      where: { userId, recipeId },
    });
    if (existing) {
      await this.favoritesRepository.remove(existing);
      return { favorited: false };
    }
    await this.favoritesRepository.save(
      this.favoritesRepository.create({ userId, recipeId }),
    );
    return { favorited: true };
  }

  async findFavorites(userId: string): Promise<Recipe[]> {
    const favorites = await this.favoritesRepository.find({
      where: { userId },
      relations: { recipe: true },
    });
    return favorites.map((favorite) => {
      favorite.recipe.isFavorite = true;
      return favorite.recipe;
    });
  }
}
