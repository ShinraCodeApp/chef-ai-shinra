import { normalizePrice } from './ingredient-prices.service';
import { IngredientUnit } from '../../common/enums';

describe('normalizePrice', () => {
  it('ticket por gramos: total del renglón -> precio por kilo', () => {
    // 350 g de arvejas a $571 (antes quedaba "$571 el gramo")
    expect(
      normalizePrice({ price: 571, unit: IngredientUnit.GRAMS, quantity: 350 }),
    ).toEqual({ price: 1631.43, unit: IngredientUnit.KILOGRAMS });
  });

  it('ticket por ml -> precio por litro', () => {
    expect(
      normalizePrice({
        price: 1606.25,
        unit: IngredientUnit.MILLILITERS,
        quantity: 520,
      }),
    ).toEqual({ price: 3088.94, unit: IngredientUnit.LITERS });
  });

  it('ticket por kilo con peso: divide por el peso', () => {
    // 1,25 kg de pollo por $8750 -> $7000 el kilo
    expect(
      normalizePrice({
        price: 8750,
        unit: IngredientUnit.KILOGRAMS,
        quantity: 1.25,
      }),
    ).toEqual({ price: 7000, unit: IngredientUnit.KILOGRAMS });
  });

  it('por unidades: precio de una unidad', () => {
    expect(
      normalizePrice({ price: 3000, unit: IngredientUnit.UNIT, quantity: 2 }),
    ).toEqual({ price: 1500, unit: IngredientUnit.UNIT });
  });

  it('sin cantidad (admin cargando precio por kilo): queda igual', () => {
    expect(
      normalizePrice({ price: 2500, unit: IngredientUnit.KILOGRAMS }),
    ).toEqual({ price: 2500, unit: IngredientUnit.KILOGRAMS });
  });
});
