// Traduce lo que se escribe en el buscador a un filtro por etiqueta o por
// condición de salud, para que buscar "vegano", "celíaco" o "diabetes" devuelva
// todas las recetas que correspondan y no sólo las que lo digan en el título.
//
// Los criterios de salud son los mismos que muestra el detalle de la receta en la
// app (app/lib/core/health_conditions.dart): si se cambian allá, cambiarlos acá.

export type SearchFilter =
  | { kind: 'tag'; tag: string }
  | { kind: 'condition'; condition: HealthConditionKey };

export type HealthConditionKey =
  | 'diabetes'
  | 'hipertension'
  | 'estrenimiento'
  | 'sobrepeso'
  | 'lactosa'
  | 'corazon'
  | 'anemia'
  | 'osteoporosis';

const TAG_SYNONYMS: Record<string, string[]> = {
  vegano: ['vegano', 'vegana', 'veganos', 'veganas', 'vegan', 'comida vegana'],
  vegetariano: [
    'vegetariano',
    'vegetariana',
    'vegetarianos',
    'vegetarianas',
    'comida vegetariana',
  ],
  sin_tacc: [
    'sin tacc',
    'sintacc',
    'celiaco',
    'celiaca',
    'celiacos',
    'celiacas',
    'celiaquia',
    'sin gluten',
  ],
  keto: ['keto', 'cetogenica', 'cetogenico', 'dieta keto'],
  proteico: [
    'proteico',
    'proteica',
    'proteicos',
    'proteicas',
    'proteina',
    'alto en proteina',
    'comida proteica',
  ],
  fitness: ['fitness', 'fit'],
  economico: ['economico', 'economica', 'economicos', 'barato', 'barata'],
  comida_cruda: ['comida cruda', 'crudo', 'cruda', 'crudivegano', 'raw'],
  hipotiroidismo: ['hipotiroidismo', 'hipotiroides', 'hipotiroideo'],
  hipertiroidismo: ['hipertiroidismo', 'hipertiroides', 'hipertiroideo'],
  bajo_yodo: [
    'bajo en yodo',
    'bajo yodo',
    'sin yodo',
    'cancer de tiroides',
    'yodo radiactivo',
  ],
  anime: ['anime', 'platos anime'],
  cerebro_sano: [
    'cerebro sano',
    'cerebro',
    'dieta mind',
    'mind',
    'memoria',
    'demencia',
    'alzheimer',
    'acv',
    'infarto cerebral',
  ],
  jugos: [
    'jugos',
    'jugo',
    'licuados',
    'licuado',
    'batido',
    'batidos',
    'smoothie',
    'bebidas',
  ],
  textura_suave: [
    'textura suave',
    'texturas suaves',
    'blando',
    'blanda',
    'facil de tragar',
    'disfagia',
    'pure',
  ],
};

const CONDITION_SYNONYMS: Record<HealthConditionKey, string[]> = {
  diabetes: [
    'diabetes',
    'diabetico',
    'diabetica',
    'resistencia a la insulina',
    'bajo en azucar',
  ],
  hipertension: [
    'hipertension',
    'hipertenso',
    'hipertensa',
    'presion alta',
    'bajo en sodio',
    'bajo en sal',
  ],
  estrenimiento: ['estrenimiento', 'alto en fibra', 'rico en fibra', 'fibra'],
  sobrepeso: ['sobrepeso', 'obesidad', 'bajar de peso', 'adelgazar', 'light'],
  lactosa: [
    'lactosa',
    'sin lactosa',
    'intolerancia a la lactosa',
    'sin lacteos',
  ],
  corazon: ['colesterol', 'corazon', 'cardiovascular', 'trigliceridos'],
  anemia: ['anemia', 'hierro', 'rico en hierro'],
  osteoporosis: ['osteoporosis', 'calcio', 'huesos'],
};

/** Minúsculas, sin tildes, sin guiones bajos y con espacios simples. */
export function normalizeSearch(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/_/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

const LOOKUP = new Map<string, SearchFilter>();
for (const [tag, words] of Object.entries(TAG_SYNONYMS)) {
  for (const w of [tag, ...words]) {
    LOOKUP.set(normalizeSearch(w), { kind: 'tag', tag });
  }
}
for (const [condition, words] of Object.entries(CONDITION_SYNONYMS)) {
  for (const w of words) {
    LOOKUP.set(normalizeSearch(w), {
      kind: 'condition',
      condition: condition as HealthConditionKey,
    });
  }
}

/** Filtro que corresponde al texto buscado, o null si no es una etiqueta. */
export function searchFilterFor(search: string): SearchFilter | null {
  return LOOKUP.get(normalizeSearch(search)) ?? null;
}

// Listas de ingredientes (mismos nombres que ingredients.seed.ts).
export const DAIRY = [
  'Leche',
  'Queso',
  'Yogur',
  'Yogur griego',
  'Mozzarella',
  'Ricota',
  'Queso crema',
  'Burrata',
  'Crema de leche',
  'Manteca',
  'Dulce de leche',
  'Leche condensada',
  'Leche evaporada',
  'Helado',
  'Chocolate blanco',
];
export const HEART_FRIENDLY = [
  'Salmón',
  'Sardinas',
  'Caballa',
  'Atún',
  'Avena',
  'Lentejas',
  'Garbanzos',
  'Porotos negros',
  'Nueces',
  'Almendras',
  'Linaza',
  'Chía',
  'Palta',
];
export const SATURATED_FAT = [
  'Manteca',
  'Panceta',
  'Chorizo',
  'Crema de leche',
  'Manteca de cerdo',
  'Morcilla',
  'Chinchulines',
  'Mollejas',
  'Riñones',
  'Dulce de leche',
  'Leche condensada',
  'Salchichas',
  'Mortadela',
  'Cochinillo',
];
export const IRON_RICH = [
  'Carne (bife)',
  'Carne picada',
  'Lentejas',
  'Garbanzos',
  'Porotos negros',
  'Mejillones',
  'Riñones',
  'Morcilla',
  'Cordero',
];
export const CALCIUM_RICH = [
  'Leche',
  'Queso',
  'Yogur',
  'Yogur griego',
  'Mozzarella',
  'Ricota',
  'Burrata',
  'Sardinas',
];
