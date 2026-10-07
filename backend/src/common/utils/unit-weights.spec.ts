import { IngredientUnit } from '../enums';
import { convertQuantity } from './unit-conversion';
import { unitWeightFor } from './unit-weights';

describe('unitWeightFor', () => {
  it('reconoce el nombre sin importar mayúsculas, acentos ni plural', () => {
    expect(unitWeightFor('Huevo')).toBe(50);
    expect(unitWeightFor('Limón')).toBe(100);
    expect(unitWeightFor('Tomates')).toBe(120);
    expect(unitWeightFor('Morrón')).toBe(150);
  });

  it('acepta variedades del mismo producto', () => {
    expect(unitWeightFor('Cebolla morada')).toBe(150);
    expect(unitWeightFor('Huevo de campo')).toBe(50);
  });

  it('no confunde productos distintos que empiezan igual', () => {
    expect(unitWeightFor('Pan rallado')).toBeNull();
    expect(unitWeightFor('Ajo en polvo')).toBeNull();
  });

  it('devuelve null si no lo conoce', () => {
    expect(unitWeightFor('Harina')).toBeNull();
    expect(unitWeightFor(null)).toBeNull();
  });
});

describe('convertQuantity con peso por unidad', () => {
  it('pasa unidades a gramos (3 cebollas ≈ 450 g)', () => {
    expect(
      convertQuantity(3, IngredientUnit.UNIT, IngredientUnit.GRAMS, 150),
    ).toBe(450);
  });

  it('pasa gramos a unidades (100 g de huevo ≈ 2 huevos)', () => {
    expect(
      convertQuantity(100, IngredientUnit.GRAMS, IngredientUnit.UNIT, 50),
    ).toBe(2);
  });

  it('kg y unidades', () => {
    expect(
      convertQuantity(1, IngredientUnit.KILOGRAMS, IngredientUnit.UNIT, 200),
    ).toBe(5);
  });

  it('sin peso conocido sigue sin convertir unidad ↔ gramos', () => {
    expect(
      convertQuantity(3, IngredientUnit.UNIT, IngredientUnit.GRAMS),
    ).toBeNull();
  });
});
