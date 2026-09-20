import { NotFoundException } from '@nestjs/common';
import { RecipesService } from './recipes.service';
import { InventoryService } from '../inventory/inventory.service';
import { IngredientUnit, RecipeDifficulty } from '../../common/enums';

describe('RecipesService', () => {
  let recipesService: RecipesService;
  let recipesRepository: { findOne: jest.Mock };
  let favoritesRepository: Record<string, jest.Mock>;
  let inventoryService: jest.Mocked<Pick<InventoryService, 'consume'>>;

  const recipe = {
    id: 'recipe-1',
    difficulty: RecipeDifficulty.EASY,
    recipeIngredients: [
      {
        ingredientId: 'ing-1',
        quantity: 2,
        unit: IngredientUnit.UNIT,
        ingredient: { name: 'Huevo' },
      },
      {
        ingredientId: 'ing-2',
        quantity: 500,
        unit: IngredientUnit.GRAMS,
        ingredient: { name: 'Harina' },
      },
    ],
  };

  beforeEach(() => {
    recipesRepository = { findOne: jest.fn() };
    favoritesRepository = {
      findOne: jest.fn(),
      save: jest.fn(),
      create: jest.fn(),
      remove: jest.fn(),
    };
    inventoryService = { consume: jest.fn().mockResolvedValue(0) };

    recipesService = new RecipesService(
      recipesRepository as any,
      favoritesRepository as any,
      inventoryService as any,
    );
  });

  describe('findOne', () => {
    it('lanza NotFoundException si la receta no existe', async () => {
      recipesRepository.findOne.mockResolvedValue(null);

      await expect(recipesService.findOne('no-existe')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('cook', () => {
    it('descuenta del inventario cada ingrediente de la receta, multiplicado por servingsMultiplier', async () => {
      recipesRepository.findOne.mockResolvedValue(recipe);

      await recipesService.cook('user-1', recipe.id, 2);

      expect(inventoryService.consume).toHaveBeenCalledTimes(2);
      expect(inventoryService.consume).toHaveBeenCalledWith(
        'user-1',
        'ing-1',
        4,
        IngredientUnit.UNIT,
      );
      expect(inventoryService.consume).toHaveBeenCalledWith(
        'user-1',
        'ing-2',
        1000,
        IngredientUnit.GRAMS,
      );
    });

    it('usa multiplicador 1 por defecto', async () => {
      recipesRepository.findOne.mockResolvedValue(recipe);

      await recipesService.cook('user-1', recipe.id);

      expect(inventoryService.consume).toHaveBeenCalledWith(
        'user-1',
        'ing-1',
        2,
        IngredientUnit.UNIT,
      );
      expect(inventoryService.consume).toHaveBeenCalledWith(
        'user-1',
        'ing-2',
        500,
        IngredientUnit.GRAMS,
      );
    });

    it('devuelve missingIngredients vacío cuando el inventario alcanza', async () => {
      recipesRepository.findOne.mockResolvedValue(recipe);

      const result = await recipesService.cook('user-1', recipe.id);

      expect(result.recipe).toBe(recipe);
      expect(result.missingIngredients).toEqual([]);
    });

    it('informa los ingredientes faltantes cuando el inventario no alcanza', async () => {
      recipesRepository.findOne.mockResolvedValue(recipe);
      inventoryService.consume.mockResolvedValueOnce(0).mockResolvedValueOnce(200);

      const result = await recipesService.cook('user-1', recipe.id);

      expect(result.missingIngredients).toEqual([
        {
          ingredientId: 'ing-2',
          name: 'Harina',
          quantity: 200,
          unit: IngredientUnit.GRAMS,
        },
      ]);
    });
  });
});
