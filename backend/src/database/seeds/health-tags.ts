// Etiquetas de tiroides que se deducen de los ingredientes al correr el seed, para
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

interface TaggableRecipe {
  dietTags: string[];
  ingredients: { ingredientName: string; notes?: string }[];
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
  return [...tags];
}
