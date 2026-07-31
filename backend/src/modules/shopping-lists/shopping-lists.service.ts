import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ShoppingList } from './entities/shopping-list.entity';
import { ShoppingListItem } from './entities/shopping-list-item.entity';
import { CreateShoppingListDto } from './dto/create-shopping-list.dto';
import { CreateShoppingListItemDto } from './dto/create-shopping-list-item.dto';
import { MealPlansService } from '../meal-plans/meal-plans.service';
import { RecipesService } from '../recipes/recipes.service';
import { InventoryService } from '../inventory/inventory.service';
import { IngredientUnit } from '../../common/enums';
import { convertQuantity } from '../../common/utils/unit-conversion';

@Injectable()
export class ShoppingListsService {
  constructor(
    @InjectRepository(ShoppingList)
    private readonly listsRepository: Repository<ShoppingList>,
    @InjectRepository(ShoppingListItem)
    private readonly itemsRepository: Repository<ShoppingListItem>,
    private readonly mealPlansService: MealPlansService,
    private readonly recipesService: RecipesService,
    private readonly inventoryService: InventoryService,
  ) {}

  create(userId: string, dto: CreateShoppingListDto): Promise<ShoppingList> {
    return this.listsRepository.save(
      this.listsRepository.create({
        userId,
        name: dto.name ?? 'Lista de compras',
      }),
    );
  }

  findAllForUser(userId: string): Promise<ShoppingList[]> {
    return this.listsRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      relations: { items: true },
    });
  }

  private async findOwned(userId: string, id: string): Promise<ShoppingList> {
    const list = await this.listsRepository.findOne({
      where: { id, userId },
      relations: { items: true },
    });
    if (!list) {
      throw new NotFoundException('Lista de compras no encontrada');
    }
    return list;
  }

  async addItem(
    userId: string,
    listId: string,
    dto: CreateShoppingListItemDto,
  ): Promise<ShoppingListItem> {
    await this.findOwned(userId, listId);
    return this.itemsRepository.save(
      this.itemsRepository.create({
        shoppingListId: listId,
        ingredientId: dto.ingredientId ?? null,
        customName: dto.customName ?? null,
        quantity: dto.quantity,
        unit: dto.unit,
        category: dto.category,
      }),
    );
  }

  async toggleChecked(
    userId: string,
    listId: string,
    itemId: string,
  ): Promise<ShoppingListItem> {
    const list = await this.findOwned(userId, listId);
    const item = list.items.find((i) => i.id === itemId);
    if (!item) {
      throw new NotFoundException('Ítem no encontrado en la lista');
    }
    item.isChecked = !item.isChecked;
    return this.itemsRepository.save(item);
  }

  async removeItem(
    userId: string,
    listId: string,
    itemId: string,
  ): Promise<void> {
    const list = await this.findOwned(userId, listId);
    const item = list.items.find((i) => i.id === itemId);
    if (!item) {
      throw new NotFoundException('Ítem no encontrado en la lista');
    }
    await this.itemsRepository.remove(item);
  }

  /**
   * Genera una lista de compras a partir de un plan de comidas: suma los ingredientes
   * de todas las recetas del plan y resta lo que el usuario ya tiene en su inventario.
   */
  async generateFromMealPlan(
    userId: string,
    mealPlanId: string,
  ): Promise<ShoppingList> {
    const mealPlan = await this.mealPlansService.findOne(userId, mealPlanId);
    const inventory = await this.inventoryService.findAllForUser(userId);

    // no se pre-suman: cada ítem puede estar en una unidad distinta, se convierten
    // recién al comparar contra lo que efectivamente necesita cada receta
    const inventoryByIngredient = new Map<
      string,
      Array<{ quantity: number; unit: IngredientUnit }>
    >();
    for (const item of inventory) {
      const list = inventoryByIngredient.get(item.ingredientId) ?? [];
      list.push({ quantity: item.quantity, unit: item.unit });
      inventoryByIngredient.set(item.ingredientId, list);
    }

    const needed = new Map<
      string,
      {
        quantity: number;
        unit: IngredientUnit;
        category: ShoppingListItem['category'];
      }
    >();

    for (const entry of mealPlan.entries) {
      const recipe = await this.recipesService.findOne(entry.recipeId);
      for (const recipeIngredient of recipe.recipeIngredients) {
        const current = needed.get(recipeIngredient.ingredientId);
        if (!current) {
          needed.set(recipeIngredient.ingredientId, {
            quantity: recipeIngredient.quantity,
            unit: recipeIngredient.unit,
            category: recipeIngredient.ingredient.category,
          });
          continue;
        }
        // suma en la unidad ya establecida para este ingrediente; si no es convertible
        // (ej. "unidad" vs "g" en dos recetas distintas) se ignora esa cantidad para no
        // mezclar magnitudes incompatibles
        const converted = convertQuantity(
          recipeIngredient.quantity,
          recipeIngredient.unit,
          current.unit,
        );
        if (converted !== null) {
          current.quantity += converted;
        }
      }
    }

    const list = await this.create(userId, {
      name: `Compras: ${mealPlan.startDate} a ${mealPlan.endDate}`,
    });

    const items: ShoppingListItem[] = [];
    for (const [ingredientId, info] of needed.entries()) {
      const alreadyHave = (
        inventoryByIngredient.get(ingredientId) ?? []
      ).reduce(
        (sum, entry) =>
          sum + (convertQuantity(entry.quantity, entry.unit, info.unit) ?? 0),
        0,
      );
      const toBuy = info.quantity - alreadyHave;
      if (toBuy <= 0) continue;
      items.push(
        this.itemsRepository.create({
          shoppingListId: list.id,
          ingredientId,
          quantity: toBuy,
          unit: info.unit,
          category: info.category,
        }),
      );
    }
    list.items = await this.itemsRepository.save(items);
    return list;
  }
}
