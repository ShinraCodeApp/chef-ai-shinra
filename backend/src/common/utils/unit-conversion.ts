import { IngredientUnit } from '../enums';

/**
 * Convierte una cantidad entre unidades de la misma magnitud (masa: g<->kg, volumen: ml<->l).
 * "unidad" no es convertible a nada más (es un conteo, no tiene una equivalencia fija).
 * Devuelve null si las unidades no son compatibles entre sí.
 */
export function convertQuantity(
  quantity: number,
  fromUnit: IngredientUnit,
  toUnit: IngredientUnit,
): number | null {
  if (fromUnit === toUnit) {
    return quantity;
  }

  const massToGrams: Partial<Record<IngredientUnit, number>> = {
    [IngredientUnit.GRAMS]: 1,
    [IngredientUnit.KILOGRAMS]: 1000,
  };
  const volumeToMl: Partial<Record<IngredientUnit, number>> = {
    [IngredientUnit.MILLILITERS]: 1,
    [IngredientUnit.LITERS]: 1000,
  };

  if (fromUnit in massToGrams && toUnit in massToGrams) {
    const grams = quantity * massToGrams[fromUnit]!;
    return grams / massToGrams[toUnit]!;
  }
  if (fromUnit in volumeToMl && toUnit in volumeToMl) {
    const ml = quantity * volumeToMl[fromUnit]!;
    return ml / volumeToMl[toUnit]!;
  }
  return null;
}
