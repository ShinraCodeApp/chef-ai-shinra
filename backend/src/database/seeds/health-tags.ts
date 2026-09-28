// Etiquetas de tiroides y de dieta vegana/vegetariana que se deducen de los ingredientes al correr el seed, para
// que las categorías "Hipotiroidismo" / "Hipertiroidismo" del inicio incluyan todas
// las recetas que corresponden sin tener que marcarlas a mano una por una.
// Las listas coinciden con app/lib/core/health_conditions.dart (el detalle de la
// receta muestra el mismo criterio): si se cambian acá, cambiarlas también allá.

const SEAFOOD = new Set([
  'Pescado (filete)',
  'Atún',
  'Salmón',
  'Camarones',
  'Mejillones',
  'Calamares',
  'Sardinas',
  'Merluza',
  'Caballa',
  'Bacalao',
  'Pulpo',
  'Vieiras',
  'Sepia',
  'Pez espada',
  'Centolla',
  'Anchoas',
  'Kanikama',
  'Alga nori',
]);

// Carnes, aves, pescados, mariscos y derivados (gelatina, salsas de pescado).
const MEAT_OR_FISH = new Set([
  ...SEAFOOD,
  'Pollo (pechuga)',
  'Carne picada',
  'Carne (bife)',
  'Costillas de cerdo',
  'Cerdo (magro)',
  'Chorizo',
  'Jamón',
  'Manteca de cerdo',
  'Charque',
  'Panceta',
  'Salchichas',
  'Cochinillo',
  'Manitas de cerdo',
  'Chinchulines',
  'Riñones',
  'Morcilla',
  'Pularda',
  'Pavo',
  'Mollejas',
  'Mortadela',
  'Conejo',
  'Cordero',
  'Salsa de pescado',
  'Salsa de ostión',
  'Salsa inglesa',
  'Gelatina sin sabor',
  'Malvaviscos',
]);

// Huevo, lácteos y miel: aptos para vegetarianos, no para veganos.
const EGG_DAIRY_HONEY = new Set([
  'Huevo',
  'Leche',
  'Queso',
  'Yogur',
  'Yogur griego',
  'Mozzarella',
  'Queso crema',
  'Manteca',
  'Mayonesa',
  'Crema de leche',
  'Burrata',
  'Leche condensada',
  'Dulce de leche',
  'Ricota',
  'Leche evaporada',
  'Helado',
  'Chocolate blanco',
  'Miel',
]);

// Pueden ser o no de origen animal según la marca o la receta (caldo de pollo o
// de verduras, proteína de suero o vegetal, galletitas con o sin manteca): no se
// usan para agregar etiquetas, pero tampoco para quitarlas.
const AMBIGUOUS = new Set(['Caldo', 'Proteína en polvo', 'Galletas']);

type SeedIngredient = { ingredientName: string; notes?: string };

function isVegetableBroth(i: SeedIngredient): boolean {
  return i.ingredientName === 'Caldo' && /verdura/i.test(i.notes ?? '');
}

function isPlantSyrup(i: SeedIngredient): boolean {
  return i.ingredientName === 'Miel' && /arce|agave/i.test(i.notes ?? '');
}

interface TaggableRecipe {
  dietTags: string[];
  ingredients: SeedIngredient[];
}

export function withHealthTags(recipe: TaggableRecipe): string[] {
  const tags = new Set(recipe.dietTags);
  const lowIodine = tags.has('bajo_yodo');
  const hasWholeEgg = recipe.ingredients.some(
    (i) =>
      i.ingredientName === 'Huevo' &&
      !(i.notes ?? '').toLowerCase().includes('clara'),
  );
  const hasSeafood = recipe.ingredients.some((i) =>
    SEAFOOD.has(i.ingredientName),
  );

  // Pescados, mariscos, algas y huevo aportan yodo y selenio.
  if (!lowIodine && (hasSeafood || hasWholeEgg)) tags.add('hipotiroidismo');
  // Las recetas bajas en yodo sirven cuando el médico indica limitar el yodo.
  if (lowIodine) {
    tags.delete('hipotiroidismo');
    tags.add('hipertiroidismo');
  }

  // Vegano / vegetariano según los ingredientes: se agrega cuando todos son
  // claramente aptos y se quita cuando alguno claramente no lo es.
  const ings = recipe.ingredients;
  const hasMeat = ings.some((i) => MEAT_OR_FISH.has(i.ingredientName));
  const hasEggDairyHoney = ings.some(
    (i) => EGG_DAIRY_HONEY.has(i.ingredientName) && !isPlantSyrup(i),
  );
  const hasAmbiguous = ings.some(
    (i) => AMBIGUOUS.has(i.ingredientName) && !isVegetableBroth(i),
  );
  if (hasMeat) {
    tags.delete('vegetariano');
    tags.delete('vegano');
  } else if (!hasAmbiguous) {
    tags.add('vegetariano');
  }
  if (hasMeat || hasEggDairyHoney) tags.delete('vegano');
  else if (!hasAmbiguous) tags.add('vegano');

  return [...tags];
}
