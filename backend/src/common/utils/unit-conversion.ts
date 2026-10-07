import { IngredientUnit } from '../enums';

/**
 * Convierte una cantidad entre unidades de la misma magnitud (masa: g<->kg, volumen: ml<->l).
 * "unidad" se convierte a peso/volumen solo si se conoce cuánto pesa una unidad de ese
 * ingrediente (`unitWeightG`, ver unit-weights.ts; para líquidos 1 ml ≈ 1 g).
 * Devuelve null si las unidades no son compatibles entre sí.
 */
export function convertQuantity(
  quantity: number,
  fromUnit: IngredientUnit,
  toUnit: IngredientUnit,
  unitWeightG?: number | null,
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

  // unidad <-> peso/volumen, con el peso promedio de una unidad del ingrediente
  if (unitWeightG && unitWeightG > 0) {
    const toBase = { ...massToGrams, ...volumeToMl };
    if (fromUnit === IngredientUnit.UNIT && toUnit in toBase) {
      return (quantity * unitWeightG) / toBase[toUnit]!;
    }
    if (toUnit === IngredientUnit.UNIT && fromUnit in toBase) {
      return (quantity * toBase[fromUnit]!) / unitWeightG;
    }
  }
  return null;
}
