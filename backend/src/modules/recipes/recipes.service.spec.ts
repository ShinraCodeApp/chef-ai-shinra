import { NotFoundException } from '@nestjs/common';
import {
  approximateQuantity,
  convertQuantity,
  RecipesService,
} from './recipes.service';
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
    inventoryService = {
      consume: jest.fn().mockResolvedValue({ shortfall: 0, depleted: false }),
    };

    recipesService = new RecipesService(
      recipesRepository as any,
      favoritesRepository as any,
      { find: jest.fn().mockResolvedValue([]) } as any, // pricesRepository
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
        undefined, // peso por unidad (el ingrediente de prueba no lo trae)
      );
      expect(inventoryService.consume).toHaveBeenCalledWith(
        'user-1',
        'ing-2',
        1000,
        IngredientUnit.GRAMS,
        undefined, // peso por unidad (el ingrediente de prueba no lo trae)
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
        undefined, // peso por unidad (el ingrediente de prueba no lo trae)
      );
      expect(inventoryService.consume).toHaveBeenCalledWith(
        'user-1',
        'ing-2',
        500,
        IngredientUnit.GRAMS,
        undefined, // peso por unidad (el ingrediente de prueba no lo trae)
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
      inventoryService.consume
        .mockResolvedValueOnce({ shortfall: 0, depleted: false })
        .mockResolvedValueOnce({ shortfall: 200, depleted: false });

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

    it('sugiere agregar a la lista de compras un ingrediente que alcanzó pero se agotó', async () => {
      recipesRepository.findOne.mockResolvedValue(recipe);
      inventoryService.consume
        .mockResolvedValueOnce({ shortfall: 0, depleted: true })
        .mockResolvedValueOnce({ shortfall: 0, depleted: false });

      const result = await recipesService.cook('user-1', recipe.id);

      expect(result.missingIngredients).toEqual([
        {
          ingredientId: 'ing-1',
          name: 'Huevo',
          quantity: 2,
          unit: IngredientUnit.UNIT,
        },
      ]);
    });
  });

  describe('getEstimatedCost', () => {
    // Los mismos números que salían en el celular: 200 ml de tomate a $1.606,25
    // el litro daban $321.250 en vez de $321,25.
    function serviceWithPrices(
      prices: Record<string, { price: number; unit: IngredientUnit }>,
    ) {
      const pricesRepository = {
        findOne: jest.fn(
          async ({ where }: any) => prices[where.ingredientId] ?? null,
        ),
      };
      return new RecipesService(
        recipesRepository as any,
        favoritesRepository as any,
        pricesRepository as any,
        inventoryService as any,
      );
    }

    it('convierte ml a litros y g a kilos antes de multiplicar', async () => {
      recipesRepository.findOne.mockResolvedValue({
        id: 'r',
        recipeIngredients: [
          {
            ingredientId: 'tomate',
            quantity: 200,
            unit: IngredientUnit.MILLILITERS,
            ingredient: { name: 'Tomate triturado' },
          },
          {
            ingredientId: 'arvejas',
            quantity: 100,
            unit: IngredientUnit.GRAMS,
            ingredient: { name: 'Arvejas' },
          },
          {
            ingredientId: 'ravioles',
            quantity: 1,
            unit: IngredientUnit.UNIT,
            ingredient: { name: 'Ravioles' },
          },
        ],
      });
      const service = serviceWithPrices({
        tomate: { price: 1606.25, unit: IngredientUnit.LITERS },
        arvejas: { price: 571.19, unit: IngredientUnit.KILOGRAMS },
        ravioles: { price: 4180.71, unit: IngredientUnit.UNIT },
      });

      const result = await service.getEstimatedCost('r');

      expect(result.breakdown.map((b) => b.lineCost)).toEqual([
        321.25, 57.12, 4180.71,
      ]);
      expect(result.totalCost).toBeCloseTo(4559.08, 2);
      expect(result.hasPartialPrices).toBe(false);
    });

    it('precio por paquete y receta en gramos: aproxima con un paquete de 500 g', async () => {
      // el caso real del celular: 300 g de tomate con el precio de la lata
      recipesRepository.findOne.mockResolvedValue({
        id: 'r',
        recipeIngredients: [
          {
            ingredientId: 'tomate',
            quantity: 300,
            unit: IngredientUnit.GRAMS,
            ingredient: { name: 'Tomate triturado' },
          },
          {
            ingredientId: 'aceite',
            quantity: 1,
            unit: IngredientUnit.UNIT,
            ingredient: { name: 'Aceite' },
          },
          {
            ingredientId: 'sal',
            quantity: 10,
            unit: IngredientUnit.GRAMS,
            ingredient: { name: 'Sal' },
          },
        ],
      });
      const service = serviceWithPrices({
        tomate: { price: 1606.25, unit: IngredientUnit.UNIT },
        aceite: { price: 3612.27, unit: IngredientUnit.UNIT },
      });

      const result = await service.getEstimatedCost('r');

      expect(result.breakdown[0].lineCost).toBe(963.75); // 300/500 de la lata
      expect(result.breakdown[0].approximate).toBe(true);
      expect(result.breakdown[1].approximate).toBe(false);
      expect(result.breakdown[2].lineCost).toBeNull(); // la sal no tiene precio cargado
      expect(result.totalCost).toBe(4576.02);
      expect(result.approximate).toBe(true);
      expect(result.hasPartialPrices).toBe(true);
    });
  });
});

describe('approximateQuantity', () => {
  it('exacto cuando se puede convertir', () => {
    expect(
      approximateQuantity(
        200,
        IngredientUnit.MILLILITERS,
        IngredientUnit.LITERS,
      ),
    ).toEqual({ quantity: 0.2, approximate: false });
  });
  it('g ≈ ml', () => {
    expect(
      approximateQuantity(300, IngredientUnit.GRAMS, IngredientUnit.LITERS),
    ).toEqual({ quantity: 0.3, approximate: true });
  });
  it('gramos contra precio por paquete: fracción de un paquete de 500 g', () => {
    expect(
      approximateQuantity(150, IngredientUnit.GRAMS, IngredientUnit.UNIT),
    ).toEqual({ quantity: 0.3, approximate: true });
  });
  it('unidades contra precio por kilo: 1 unidad ≈ 100 g', () => {
    expect(
      approximateQuantity(2, IngredientUnit.UNIT, IngredientUnit.KILOGRAMS),
    ).toEqual({ quantity: 0.2, approximate: true });
  });
});

describe('convertQuantity', () => {
  it('convierte dentro de la misma magnitud', () => {
    expect(
      convertQuantity(200, IngredientUnit.MILLILITERS, IngredientUnit.LITERS),
    ).toBe(0.2);
    expect(
      convertQuantity(1.5, IngredientUnit.KILOGRAMS, IngredientUnit.GRAMS),
    ).toBe(1500);
    expect(convertQuantity(3, IngredientUnit.UNIT, IngredientUnit.UNIT)).toBe(
      3,
    );
  });
  it('devuelve null entre magnitudes distintas', () => {
    expect(
      convertQuantity(100, IngredientUnit.GRAMS, IngredientUnit.LITERS),
    ).toBeNull();
    expect(
      convertQuantity(1, IngredientUnit.UNIT, IngredientUnit.KILOGRAMS),
    ).toBeNull();
  });
});
