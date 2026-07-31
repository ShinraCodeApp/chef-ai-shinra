import { IngredientUnit } from '../enums';
import { convertQuantity } from './unit-conversion';

describe('convertQuantity', () => {
  it('devuelve la misma cantidad si las unidades son iguales', () => {
    expect(convertQuantity(5, IngredientUnit.GRAMS, IngredientUnit.GRAMS)).toBe(
      5,
    );
  });

  it('convierte kg a g', () => {
    expect(
      convertQuantity(1, IngredientUnit.KILOGRAMS, IngredientUnit.GRAMS),
    ).toBe(1000);
  });

  it('convierte g a kg', () => {
    expect(
      convertQuantity(2500, IngredientUnit.GRAMS, IngredientUnit.KILOGRAMS),
    ).toBe(2.5);
  });

  it('convierte l a ml', () => {
    expect(
      convertQuantity(1.5, IngredientUnit.LITERS, IngredientUnit.MILLILITERS),
    ).toBe(1500);
  });

  it('convierte ml a l', () => {
    expect(
      convertQuantity(250, IngredientUnit.MILLILITERS, IngredientUnit.LITERS),
    ).toBe(0.25);
  });

  it('devuelve null para unidades incompatibles (masa vs volumen)', () => {
    expect(
      convertQuantity(1, IngredientUnit.KILOGRAMS, IngredientUnit.LITERS),
    ).toBeNull();
  });

  it('devuelve null cuando alguna de las unidades es "unidad" y difieren', () => {
    expect(
      convertQuantity(3, IngredientUnit.UNIT, IngredientUnit.GRAMS),
    ).toBeNull();
  });
});
