import { IngredientUnit, RecipeDifficulty } from '../../common/enums';
import type { SeedRecipe } from './recipes.seed';

/**
 * Jugos y licuados (etiqueta "jugos"). Recetas propias. Las descripciones
 * evitan promesas de salud sin respaldo ("detox", "depurativo",
 * "antiinflamatorio"): dicen lo que el jugo aporta de verdad.
 * Los que llevan hojas verdes avisan sobre anticoagulantes (vitamina K).
 */
const G = IngredientUnit.GRAMS;
const ML = IngredientUnit.MILLILITERS;
const UN = IngredientUnit.UNIT;

const FIBRA =
  'Licuado con la pulpa conserva la fibra y llena más que colado. Si tenés diabetes, tomalo con una comida y preferí los que llevan más verdura que fruta.';
const FIBER =
  'Blended with the pulp it keeps the fiber and is more filling than strained. If you have diabetes, drink it with a meal and prefer the ones with more vegetables than fruit.';
const VITAMINA_K =
  'Si tomás anticoagulantes (warfarina, acenocumarol), las hojas verdes tienen vitamina K: consultá a tu médico antes de tomarlo seguido.';
const VITAMIN_K =
  'If you take blood thinners (warfarin, acenocoumarol), leafy greens contain vitamin K: ask your doctor before drinking it often.';

export const juiceRecipes: SeedRecipe[] = [
  {
    title: 'Jugo de zanahoria, naranja y jengibre',
    description:
      'Jugo naranja de zanahoria y naranja con un toque picante de jengibre y cúrcuma. Aporta vitamina C y betacaroteno (vitamina A).',
    servings: 2,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegano', 'vegetariano', 'sin_tacc', 'economico'],
    estimatedCostTotal: 2000,
    nutrition: {
      calories: 120,
      proteinG: 2,
      fatG: 0.5,
      carbsG: 28,
      fiberG: 4,
      sugarG: 19,
      sodiumMg: 70,
    },
    instructions: [
      'Pelar las zanahorias y cortarlas en trozos.',
      'Exprimir las naranjas y el limón.',
      'Licuar las zanahorias con el jugo de naranja y de limón, el jengibre pelado y la cúrcuma hasta que quede liso.',
      'Si queda muy espeso, agregar agua fría. Colarlo es opcional.',
    ],
    tips: [FIBRA],
    ingredients: [
      { ingredientName: 'Zanahoria', quantity: 3, unit: UN },
      { ingredientName: 'Naranja', quantity: 3, unit: UN },
      { ingredientName: 'Limón', quantity: 1, unit: UN, notes: 'medio' },
      {
        ingredientName: 'Jengibre',
        quantity: 10,
        unit: G,
        notes: 'un trocito pelado',
      },
      {
        ingredientName: 'Cúrcuma',
        quantity: 1,
        unit: G,
        notes: 'una pizca, o un trocito fresco',
      },
      {
        ingredientName: 'Agua',
        quantity: 100,
        unit: ML,
        notes: 'fría, opcional',
      },
    ],
    en: {
      title: 'Carrot, orange and ginger juice',
      description:
        'An orange juice of carrot and orange with a spicy touch of ginger and turmeric. It provides vitamin C and beta-carotene (vitamin A).',
      instructions: [
        'Peel the carrots and cut them into chunks.',
        'Juice the oranges and the lemon.',
        'Blend the carrots with the orange and lemon juice, the peeled ginger and turmeric until smooth.',
        'If too thick, add cold water. Straining is optional.',
      ],
      tips: [FIBER],
      ingredientNotes: [
        null,
        null,
        'half',
        'a small peeled piece',
        'a pinch, or a small fresh piece',
        'cold, optional',
      ],
    },
  },
  {
    title: 'Bebida de pepino, manzana verde y agua de coco',
    description:
      'Bebida fresca y liviana de pepino, manzana verde, limón y menta con agua de coco, ideal para hidratarse en días de calor.',
    servings: 2,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegano', 'vegetariano', 'sin_tacc'],
    estimatedCostTotal: 3500,
    nutrition: {
      calories: 95,
      proteinG: 1.5,
      fatG: 0.5,
      carbsG: 22,
      fiberG: 4,
      sugarG: 16,
      sodiumMg: 130,
    },
    instructions: [
      'Lavar el pepino y la manzana y cortarlos en trozos (la cáscara se puede dejar).',
      'Licuar con el agua de coco, el jugo de limón y las hojas de menta.',
      'Servir bien frío, con hielo si te gusta.',
    ],
    tips: [
      'Si no conseguís agua de coco, usá agua fría: queda igual de rica.',
      FIBRA,
    ],
    ingredients: [
      { ingredientName: 'Pepino', quantity: 1, unit: UN },
      { ingredientName: 'Manzana', quantity: 1, unit: UN, notes: 'verde' },
      { ingredientName: 'Agua de coco', quantity: 300, unit: ML },
      { ingredientName: 'Limón', quantity: 1, unit: UN, notes: 'el jugo' },
      { ingredientName: 'Menta', quantity: 5, unit: G, notes: 'unas hojas' },
    ],
    en: {
      title: 'Cucumber, green apple and coconut water drink',
      description:
        'A fresh, light drink of cucumber, green apple, lemon and mint with coconut water, great for staying hydrated on hot days.',
      instructions: [
        'Wash the cucumber and apple and cut them into chunks (you can leave the peel on).',
        'Blend with the coconut water, lemon juice and mint leaves.',
        'Serve very cold, with ice if you like.',
      ],
      tips: [
        "If you can't find coconut water, use cold water: it's just as good.",
        FIBER,
      ],
      ingredientNotes: [null, 'green', null, 'juiced', 'a few leaves'],
    },
  },
  {
    title: 'Licuado morado de repollo, ananá e hinojo',
    description:
      'Licuado de color violeta intenso con repollo colorado, ananá, hinojo, limón y menta: dulce, fresco y con fibra.',
    servings: 2,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegano', 'vegetariano', 'sin_tacc'],
    estimatedCostTotal: 3500,
    nutrition: {
      calories: 110,
      proteinG: 2,
      fatG: 0.4,
      carbsG: 26,
      fiberG: 5,
      sugarG: 18,
      sodiumMg: 40,
    },
    instructions: [
      'Cortar el repollo, el ananá pelado y el hinojo en trozos chicos.',
      'Licuar con el agua, el jugo de limón y la menta hasta que quede liso.',
      'Colar si preferís una textura más fina y servir frío.',
    ],
    tips: ['El ananá endulza: no hace falta agregar azúcar.', FIBRA],
    ingredients: [
      { ingredientName: 'Repollo colorado', quantity: 100, unit: G },
      {
        ingredientName: 'Piña',
        quantity: 250,
        unit: G,
        notes: 'ananá, pelado',
      },
      { ingredientName: 'Hinojo', quantity: 80, unit: G, notes: 'el bulbo' },
      { ingredientName: 'Agua', quantity: 300, unit: ML, notes: 'fría' },
      {
        ingredientName: 'Limón',
        quantity: 1,
        unit: UN,
        notes: 'medio, el jugo',
      },
      { ingredientName: 'Menta', quantity: 5, unit: G },
    ],
    en: {
      title: 'Purple cabbage, pineapple and fennel smoothie',
      description:
        'A deep purple smoothie of red cabbage, pineapple, fennel, lemon and mint: sweet, fresh and full of fiber.',
      instructions: [
        'Cut the cabbage, peeled pineapple and fennel into small pieces.',
        'Blend with the water, lemon juice and mint until smooth.',
        'Strain if you prefer a finer texture and serve cold.',
      ],
      tips: ['The pineapple sweetens it: no need to add sugar.', FIBER],
      ingredientNotes: [
        null,
        'peeled',
        'the bulb',
        'cold',
        'half, juiced',
        null,
      ],
    },
  },
  {
    title: 'Agua fresca de sandía, frutillas y albahaca',
    description:
      'Bebida roja de sandía y frutillas con albahaca y té frío de flor de jamaica (hibisco). Muy hidratante: la sandía es más del 90 % agua.',
    servings: 4,
    prepTimeMinutes: 15,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegano', 'vegetariano', 'sin_tacc'],
    estimatedCostTotal: 4000,
    nutrition: {
      calories: 70,
      proteinG: 1.2,
      fatG: 0.3,
      carbsG: 17,
      fiberG: 1.5,
      sugarG: 14,
      sodiumMg: 4,
    },
    instructions: [
      'Preparar el té: dejar la flor de jamaica en 300 ml de agua caliente 10 minutos, colar y enfriar.',
      'Licuar la sandía sin semillas con las frutillas y las hojas de albahaca.',
      'Mezclar con el té frío y servir con hielo.',
    ],
    tips: [
      'Sin flor de jamaica queda igual de rica: reemplazala por agua fría.',
    ],
    ingredients: [
      {
        ingredientName: 'Sandía',
        quantity: 800,
        unit: G,
        notes: 'sin cáscara ni semillas',
      },
      { ingredientName: 'Frutillas', quantity: 200, unit: G },
      { ingredientName: 'Albahaca', quantity: 5, unit: G, notes: 'unas hojas' },
      {
        ingredientName: 'Flor de jamaica',
        quantity: 10,
        unit: G,
        notes: 'hibisco seco, opcional',
      },
      { ingredientName: 'Agua', quantity: 300, unit: ML },
    ],
    en: {
      title: 'Watermelon, strawberry and basil agua fresca',
      description:
        'A red drink of watermelon and strawberries with basil and cold hibiscus tea. Very hydrating: watermelon is over 90% water.',
      instructions: [
        'Make the tea: steep the hibiscus in 300 ml of hot water for 10 minutes, strain and cool.',
        'Blend the seedless watermelon with the strawberries and basil leaves.',
        'Mix with the cold tea and serve over ice.',
      ],
      tips: ["Without hibiscus it's just as good: use cold water instead."],
      ingredientNotes: [
        'rind and seeds removed',
        null,
        'a few leaves',
        'dried hibiscus, optional',
        null,
      ],
    },
  },
  {
    title: 'Jugo verde de espinaca, pepino y manzana',
    description:
      'Jugo verde con más verdura que fruta: espinaca, pepino y apio con manzana verde, jengibre, menta y limón.',
    servings: 2,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegano', 'vegetariano', 'sin_tacc', 'economico'],
    estimatedCostTotal: 2500,
    nutrition: {
      calories: 85,
      proteinG: 2.5,
      fatG: 0.5,
      carbsG: 19,
      fiberG: 5,
      sugarG: 12,
      sodiumMg: 80,
    },
    instructions: [
      'Lavar bien la espinaca, el pepino, el apio y la manzana.',
      'Cortar todo en trozos y licuar con el agua, el jengibre, la menta y el jugo de limón.',
      'Licuar hasta que quede bien liso y servir enseguida.',
    ],
    tips: [VITAMINA_K, FIBRA],
    ingredients: [
      {
        ingredientName: 'Espinaca',
        quantity: 60,
        unit: G,
        notes: 'un puñado grande',
      },
      { ingredientName: 'Pepino', quantity: 1, unit: UN },
      { ingredientName: 'Apio', quantity: 1, unit: UN, notes: 'rama' },
      { ingredientName: 'Manzana', quantity: 1, unit: UN, notes: 'verde' },
      { ingredientName: 'Agua', quantity: 250, unit: ML, notes: 'fría' },
      { ingredientName: 'Jengibre', quantity: 5, unit: G },
      { ingredientName: 'Menta', quantity: 3, unit: G },
      {
        ingredientName: 'Limón',
        quantity: 1,
        unit: UN,
        notes: 'medio, el jugo',
      },
    ],
    en: {
      title: 'Green juice with spinach, cucumber and apple',
      description:
        'A green juice with more vegetables than fruit: spinach, cucumber and celery with green apple, ginger, mint and lemon.',
      instructions: [
        'Wash the spinach, cucumber, celery and apple well.',
        'Cut everything into chunks and blend with the water, ginger, mint and lemon juice.',
        'Blend until very smooth and serve right away.',
      ],
      tips: [VITAMIN_K, FIBER],
      ingredientNotes: [
        'a big handful',
        null,
        'stalk',
        'green',
        'cold',
        null,
        null,
        'half, juiced',
      ],
    },
  },
  {
    title: 'Licuado de banana y frutillas',
    description:
      'El licuado clásico de la merienda: banana, frutillas y leche, cremoso y sin azúcar agregada.',
    servings: 2,
    prepTimeMinutes: 5,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegetariano', 'sin_tacc', 'economico'],
    estimatedCostTotal: 2000,
    nutrition: {
      calories: 190,
      proteinG: 7,
      fatG: 4,
      carbsG: 34,
      fiberG: 4,
      sugarG: 24,
      sodiumMg: 60,
    },
    instructions: [
      'Pelar la banana y lavar las frutillas.',
      'Licuar todo con la leche fría hasta que quede espumoso.',
      'Servir enseguida.',
    ],
    tips: [
      'Con la banana congelada en rodajas queda más espeso, como un helado.',
    ],
    ingredients: [
      { ingredientName: 'Banana', quantity: 1, unit: UN },
      { ingredientName: 'Frutillas', quantity: 150, unit: G },
      {
        ingredientName: 'Leche',
        quantity: 300,
        unit: ML,
        notes: 'fría, o bebida vegetal',
      },
    ],
    en: {
      title: 'Banana and strawberry smoothie',
      description:
        'The classic afternoon smoothie: banana, strawberries and milk, creamy with no added sugar.',
      instructions: [
        'Peel the banana and wash the strawberries.',
        'Blend everything with the cold milk until frothy.',
        'Serve right away.',
      ],
      tips: ['With frozen banana slices it gets thicker, like ice cream.'],
      ingredientNotes: [null, null, 'cold, or plant-based milk'],
    },
  },
  {
    title: 'Licuado de durazno y avena',
    description:
      'Licuado que funciona como desayuno: durazno, avena, yogur y canela. Llena y tiene fibra.',
    servings: 2,
    prepTimeMinutes: 5,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegetariano', 'economico'],
    estimatedCostTotal: 2000,
    nutrition: {
      calories: 230,
      proteinG: 10,
      fatG: 5,
      carbsG: 38,
      fiberG: 4,
      sugarG: 20,
      sodiumMg: 80,
    },
    instructions: [
      'Licuar la avena con la leche 30 segundos para que se ablande.',
      'Agregar el durazno sin carozo, el yogur y la canela, y licuar hasta que esté liso.',
      'Servir frío.',
    ],
    ingredients: [
      { ingredientName: 'Avena', quantity: 30, unit: G },
      { ingredientName: 'Leche', quantity: 250, unit: ML },
      {
        ingredientName: 'Durazno',
        quantity: 2,
        unit: UN,
        notes: 'o en almíbar escurrido',
      },
      { ingredientName: 'Yogur', quantity: 100, unit: G, notes: 'natural' },
      { ingredientName: 'Canela', quantity: 1, unit: G },
    ],
    en: {
      title: 'Peach and oat smoothie',
      description:
        'A smoothie that works as breakfast: peach, oats, yogurt and cinnamon. Filling and high in fiber.',
      instructions: [
        'Blend the oats with the milk for 30 seconds to soften them.',
        'Add the pitted peach, yogurt and cinnamon and blend until smooth.',
        'Serve cold.',
      ],
      ingredientNotes: [null, null, 'or canned, drained', 'plain', null],
    },
  },
  {
    title: 'Batido verde de banana, espinaca y palta',
    description:
      'Batido verde cremoso: la banana y la palta le dan textura y dulzor, y la espinaca casi no se siente.',
    servings: 2,
    prepTimeMinutes: 5,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegetariano', 'sin_tacc'],
    estimatedCostTotal: 3000,
    nutrition: {
      calories: 240,
      proteinG: 7,
      fatG: 11,
      carbsG: 32,
      fiberG: 7,
      sugarG: 17,
      sodiumMg: 90,
    },
    instructions: [
      'Pelar la banana y la palta.',
      'Licuar con la espinaca, la leche y la miel hasta que quede bien liso.',
      'Servir enseguida.',
    ],
    tips: [VITAMINA_K],
    ingredients: [
      { ingredientName: 'Banana', quantity: 1, unit: UN },
      { ingredientName: 'Palta', quantity: 1, unit: UN, notes: 'media' },
      { ingredientName: 'Espinaca', quantity: 40, unit: G },
      {
        ingredientName: 'Leche',
        quantity: 300,
        unit: ML,
        notes: 'o bebida vegetal',
      },
      { ingredientName: 'Miel', quantity: 10, unit: G, notes: 'opcional' },
    ],
    en: {
      title: 'Green smoothie with banana, spinach and avocado',
      description:
        'A creamy green smoothie: banana and avocado give it texture and sweetness, and you barely taste the spinach.',
      instructions: [
        'Peel the banana and avocado.',
        'Blend with the spinach, milk and honey until very smooth.',
        'Serve right away.',
      ],
      tips: [VITAMIN_K],
      ingredientNotes: [null, 'half', null, 'or plant-based milk', 'optional'],
    },
  },
  {
    title: 'Licuado de mango y maracuyá',
    description:
      'Licuado tropical de mango y maracuyá con yogur: ácido, dulce y muy perfumado.',
    servings: 2,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegetariano', 'sin_tacc'],
    estimatedCostTotal: 4000,
    nutrition: {
      calories: 200,
      proteinG: 6,
      fatG: 3,
      carbsG: 38,
      fiberG: 5,
      sugarG: 32,
      sodiumMg: 50,
    },
    instructions: [
      'Pelar el mango y cortarlo en cubos.',
      'Sacar la pulpa de los maracuyás con una cuchara.',
      'Licuar el mango con la pulpa, el yogur y el agua fría. Colar si no querés las semillas.',
    ],
    ingredients: [
      { ingredientName: 'Mango', quantity: 1, unit: UN },
      { ingredientName: 'Maracuyá', quantity: 2, unit: UN },
      { ingredientName: 'Yogur', quantity: 150, unit: G, notes: 'natural' },
      { ingredientName: 'Agua', quantity: 150, unit: ML, notes: 'fría' },
    ],
    en: {
      title: 'Mango and passion fruit smoothie',
      description:
        'A tropical smoothie of mango and passion fruit with yogurt: tangy, sweet and very fragrant.',
      instructions: [
        'Peel the mango and cut it into cubes.',
        'Scoop out the passion fruit pulp with a spoon.',
        "Blend the mango with the pulp, yogurt and cold water. Strain if you don't want the seeds.",
      ],
      ingredientNotes: [null, null, 'plain', 'cold'],
    },
  },
  {
    title: 'Licuado de frutos rojos y yogur',
    description:
      'Licuado violeta de frutillas y arándanos con yogur y chía. Los frutos rojos son uno de los grupos que destaca la dieta MIND.',
    servings: 2,
    prepTimeMinutes: 5,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'cerebro_sano', 'vegetariano', 'sin_tacc'],
    estimatedCostTotal: 4000,
    nutrition: {
      calories: 180,
      proteinG: 9,
      fatG: 5,
      carbsG: 26,
      fiberG: 6,
      sugarG: 18,
      sodiumMg: 60,
    },
    instructions: [
      'Licuar las frutillas y los arándanos con el yogur y la leche.',
      'Agregar la chía, licuar unos segundos y dejar reposar 5 minutos para que espese.',
      'Servir frío.',
    ],
    tips: [
      'Los frutos rojos congelados funcionan igual y son más baratos fuera de temporada.',
    ],
    ingredients: [
      { ingredientName: 'Frutillas', quantity: 150, unit: G },
      { ingredientName: 'Arándanos', quantity: 80, unit: G },
      {
        ingredientName: 'Yogur',
        quantity: 200,
        unit: G,
        notes: 'natural, sin azúcar',
      },
      { ingredientName: 'Leche', quantity: 100, unit: ML },
      { ingredientName: 'Semillas de chía', quantity: 10, unit: G },
    ],
    en: {
      title: 'Berry and yogurt smoothie',
      description:
        'A purple smoothie of strawberries and blueberries with yogurt and chia. Berries are one of the food groups the MIND diet highlights.',
      instructions: [
        'Blend the strawberries and blueberries with the yogurt and milk.',
        'Add the chia, blend for a few seconds and let it rest 5 minutes to thicken.',
        'Serve cold.',
      ],
      tips: ['Frozen berries work just as well and are cheaper out of season.'],
      ingredientNotes: [null, null, 'plain, unsweetened', null, null],
    },
  },
  {
    title: 'Jugo de remolacha, zanahoria y manzana',
    description:
      'Jugo de color rojo intenso, dulce y terroso, con un toque de jengibre y limón.',
    servings: 2,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegano', 'vegetariano', 'sin_tacc', 'economico'],
    estimatedCostTotal: 2000,
    nutrition: {
      calories: 120,
      proteinG: 2.5,
      fatG: 0.4,
      carbsG: 28,
      fiberG: 6,
      sugarG: 20,
      sodiumMg: 110,
    },
    instructions: [
      'Pelar la remolacha y la zanahoria y cortarlas en trozos chicos.',
      'Licuar con la manzana, el agua, el jengibre y el jugo de limón hasta que quede liso.',
      'Colar si querés una textura más fina.',
    ],
    tips: [
      'La remolacha puede teñir la orina o la materia fecal de rojo: es normal y no es sangre.',
      FIBRA,
    ],
    ingredients: [
      { ingredientName: 'Remolacha', quantity: 1, unit: UN, notes: 'cruda' },
      { ingredientName: 'Zanahoria', quantity: 2, unit: UN },
      { ingredientName: 'Manzana', quantity: 1, unit: UN },
      { ingredientName: 'Agua', quantity: 300, unit: ML, notes: 'fría' },
      { ingredientName: 'Jengibre', quantity: 5, unit: G },
      {
        ingredientName: 'Limón',
        quantity: 1,
        unit: UN,
        notes: 'medio, el jugo',
      },
    ],
    en: {
      title: 'Beet, carrot and apple juice',
      description:
        'A deep red juice, sweet and earthy, with a touch of ginger and lemon.',
      instructions: [
        'Peel the beet and carrot and cut them into small pieces.',
        'Blend with the apple, water, ginger and lemon juice until smooth.',
        'Strain if you want a finer texture.',
      ],
      tips: [
        'Beets can turn urine or stool red: this is normal and is not blood.',
        FIBER,
      ],
      ingredientNotes: ['raw', null, null, 'cold', null, 'half, juiced'],
    },
  },
  {
    title: 'Licuado de banana, cacao y mantequilla de maní',
    description:
      'Licuado con proteína para después de entrenar o una merienda que llene: banana, cacao amargo, mantequilla de maní y leche.',
    servings: 2,
    prepTimeMinutes: 5,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegetariano', 'proteico', 'sin_tacc'],
    estimatedCostTotal: 2500,
    nutrition: {
      calories: 320,
      proteinG: 13,
      fatG: 14,
      carbsG: 38,
      fiberG: 5,
      sugarG: 22,
      sodiumMg: 130,
    },
    instructions: [
      'Pelar la banana.',
      'Licuar con la leche, la mantequilla de maní y el cacao hasta que quede cremoso.',
      'Servir frío.',
    ],
    ingredients: [
      { ingredientName: 'Banana', quantity: 2, unit: UN },
      { ingredientName: 'Leche', quantity: 350, unit: ML },
      {
        ingredientName: 'Mantequilla de maní',
        quantity: 30,
        unit: G,
        notes: '2 cucharadas',
      },
      {
        ingredientName: 'Cacao amargo',
        quantity: 10,
        unit: G,
        notes: '1 cucharada',
      },
    ],
    en: {
      title: 'Banana, cocoa and peanut butter smoothie',
      description:
        'A protein smoothie for after a workout or a filling snack: banana, unsweetened cocoa, peanut butter and milk.',
      instructions: [
        'Peel the bananas.',
        'Blend with the milk, peanut butter and cocoa until creamy.',
        'Serve cold.',
      ],
      ingredientNotes: [null, null, '2 tablespoons', '1 tablespoon'],
    },
  },
  {
    title: 'Limonada de menta y jengibre',
    description:
      'Limonada casera con menta y jengibre, poco dulce y muy refrescante.',
    servings: 4,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegano', 'vegetariano', 'sin_tacc', 'economico'],
    estimatedCostTotal: 1500,
    nutrition: {
      calories: 45,
      proteinG: 0.3,
      fatG: 0.1,
      carbsG: 12,
      fiberG: 0.5,
      sugarG: 10,
      sodiumMg: 5,
    },
    instructions: [
      'Exprimir los limones.',
      'Licuar el jugo con el agua, la menta, el jengibre y la miel o el azúcar.',
      'Colar y servir con mucho hielo.',
    ],
    tips: ['Para que sea sin azúcar, reemplazá la miel por edulcorante.'],
    ingredients: [
      { ingredientName: 'Limón', quantity: 4, unit: UN },
      {
        ingredientName: 'Agua',
        quantity: 1,
        unit: IngredientUnit.LITERS,
        notes: 'fría',
      },
      { ingredientName: 'Menta', quantity: 10, unit: G },
      { ingredientName: 'Jengibre', quantity: 10, unit: G },
      {
        ingredientName: 'Miel',
        quantity: 40,
        unit: G,
        notes: 'o azúcar, a gusto',
      },
    ],
    en: {
      title: 'Mint and ginger lemonade',
      description:
        'Homemade lemonade with mint and ginger, lightly sweet and very refreshing.',
      instructions: [
        'Juice the lemons.',
        'Blend the juice with the water, mint, ginger and honey or sugar.',
        'Strain and serve over plenty of ice.',
      ],
      tips: ['For a sugar-free version, replace the honey with sweetener.'],
      ingredientNotes: [null, 'cold', null, null, 'or sugar, to taste'],
    },
  },
  {
    title: 'Licuado de melón y menta',
    description:
      'Licuado suave y muy fresco de melón con menta y limón, perfecto para el verano.',
    servings: 2,
    prepTimeMinutes: 5,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegano', 'vegetariano', 'sin_tacc', 'economico'],
    estimatedCostTotal: 2000,
    nutrition: {
      calories: 80,
      proteinG: 1.5,
      fatG: 0.3,
      carbsG: 19,
      fiberG: 1.5,
      sugarG: 17,
      sodiumMg: 30,
    },
    instructions: [
      'Pelar el melón, sacarle las semillas y cortarlo en cubos.',
      'Licuar con el agua fría, la menta y el jugo de limón.',
      'Servir enseguida, bien frío.',
    ],
    ingredients: [
      {
        ingredientName: 'Melón',
        quantity: 500,
        unit: G,
        notes: 'sin cáscara ni semillas',
      },
      { ingredientName: 'Agua', quantity: 200, unit: ML, notes: 'fría' },
      { ingredientName: 'Menta', quantity: 5, unit: G },
      {
        ingredientName: 'Limón',
        quantity: 1,
        unit: UN,
        notes: 'medio, el jugo',
      },
    ],
    en: {
      title: 'Melon and mint smoothie',
      description:
        'A mild, very refreshing smoothie of melon with mint and lemon, perfect for summer.',
      instructions: [
        'Peel and seed the melon and cut it into cubes.',
        'Blend with the cold water, mint and lemon juice.',
        'Serve right away, very cold.',
      ],
      ingredientNotes: ['rind and seeds removed', 'cold', null, 'half, juiced'],
    },
  },
  {
    title: 'Jugo de kiwi, pera y espinaca',
    description:
      'Jugo verde dulce de kiwi y pera con espinaca. El kiwi aporta mucha vitamina C.',
    servings: 2,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['jugos', 'vegano', 'vegetariano', 'sin_tacc'],
    estimatedCostTotal: 3000,
    nutrition: {
      calories: 120,
      proteinG: 2,
      fatG: 0.6,
      carbsG: 29,
      fiberG: 6,
      sugarG: 19,
      sodiumMg: 25,
    },
    instructions: [
      'Pelar los kiwis y cortar la pera en trozos, sin las semillas.',
      'Licuar con la espinaca y el agua fría hasta que quede liso.',
      'Servir enseguida.',
    ],
    tips: [VITAMINA_K, FIBRA],
    ingredients: [
      { ingredientName: 'Kiwi', quantity: 2, unit: UN },
      { ingredientName: 'Pera', quantity: 1, unit: UN },
      { ingredientName: 'Espinaca', quantity: 40, unit: G },
      { ingredientName: 'Agua', quantity: 250, unit: ML, notes: 'fría' },
    ],
    en: {
      title: 'Kiwi, pear and spinach juice',
      description:
        'A sweet green juice of kiwi and pear with spinach. Kiwi is very high in vitamin C.',
      instructions: [
        'Peel the kiwis and cut the pear into pieces, without the seeds.',
        'Blend with the spinach and cold water until smooth.',
        'Serve right away.',
      ],
      tips: [VITAMIN_K, FIBER],
      ingredientNotes: [null, null, null, 'cold'],
    },
  },
];
