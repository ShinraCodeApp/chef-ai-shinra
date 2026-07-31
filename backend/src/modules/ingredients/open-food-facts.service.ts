import { Injectable, Logger } from '@nestjs/common';
import { IngredientCategory, IngredientUnit } from '../../common/enums';
import { CreateIngredientDto } from './dto/create-ingredient.dto';

interface OpenFoodFactsResponse {
  status: number;
  product?: {
    product_name?: string;
    generic_name?: string;
    image_url?: string;
    categories_tags?: string[];
    nutriments?: Record<string, number>;
  };
}

const CATEGORY_KEYWORDS: Array<[string, IngredientCategory]> = [
  ['meat', IngredientCategory.CARNES],
  ['fish', IngredientCategory.CARNES],
  ['vegetable', IngredientCategory.VERDURAS],
  ['fruit', IngredientCategory.FRUTAS],
  ['dairy', IngredientCategory.LACTEOS],
  ['milk', IngredientCategory.LACTEOS],
  ['cheese', IngredientCategory.LACTEOS],
  ['frozen', IngredientCategory.CONGELADOS],
  ['beverage', IngredientCategory.BEBIDAS],
  ['drink', IngredientCategory.BEBIDAS],
  ['bread', IngredientCategory.PANADERIA],
  ['bakery', IngredientCategory.PANADERIA],
  ['spice', IngredientCategory.CONDIMENTOS],
  ['sauce', IngredientCategory.CONDIMENTOS],
  ['clean', IngredientCategory.LIMPIEZA],
];

/**
 * Open Food Facts (openfoodfacts.org) es una base de datos pública y gratuita de
 * productos con código de barras, sin necesidad de API key. Se usa para autocompletar
 * el catálogo de ingredientes cuando se escanea un código EAN/UPC que no está en la app.
 */
@Injectable()
export class OpenFoodFactsService {
  private readonly logger = new Logger(OpenFoodFactsService.name);

  async lookup(barcode: string): Promise<CreateIngredientDto | null> {
    try {
      const response = await fetch(
        `https://world.openfoodfacts.org/api/v2/product/${encodeURIComponent(barcode)}.json`,
      );
      if (!response.ok) {
        return null;
      }
      const data = (await response.json()) as OpenFoodFactsResponse;
      if (data.status !== 1 || !data.product) {
        return null;
      }
      return this.mapToIngredient(barcode, data.product);
    } catch (error) {
      this.logger.warn(
        `Fallo consultando Open Food Facts para ${barcode}: ${error}`,
      );
      return null;
    }
  }

  private mapToIngredient(
    barcode: string,
    product: NonNullable<OpenFoodFactsResponse['product']>,
  ): CreateIngredientDto | null {
    const name = product.product_name || product.generic_name;
    if (!name) {
      return null;
    }
    const nutriments = product.nutriments ?? {};
    const category = this.guessCategory(product.categories_tags ?? []);

    return {
      name,
      category,
      unit: IngredientUnit.UNIT,
      barcode,
      imageUrl: product.image_url,
      caloriesPer100g: nutriments['energy-kcal_100g'],
      proteinPer100g: nutriments['proteins_100g'],
      fatPer100g: nutriments['fat_100g'],
      carbsPer100g: nutriments['carbohydrates_100g'],
      fiberPer100g: nutriments['fiber_100g'],
      sugarPer100g: nutriments['sugars_100g'],
      sodiumPer100g: nutriments['sodium_100g'],
    };
  }

  private guessCategory(categoryTags: string[]): IngredientCategory {
    const haystack = categoryTags.join(' ').toLowerCase();
    for (const [keyword, category] of CATEGORY_KEYWORDS) {
      if (haystack.includes(keyword)) {
        return category;
      }
    }
    return IngredientCategory.OTROS;
  }
}
