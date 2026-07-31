import 'reflect-metadata';
import * as path from 'path';
import { DataSource, ILike } from 'typeorm';
import * as dotenv from 'dotenv';
import { Ingredient } from '../../modules/ingredients/entities/ingredient.entity';
import { Recipe } from '../../modules/recipes/entities/recipe.entity';
import { IngredientUnit, RecipeDifficulty } from '../../common/enums';

dotenv.config();

interface SeedRecipeIngredient {
  ingredientName: string;
  quantity: number;
  unit: IngredientUnit;
  notes?: string;
}

interface SeedRecipe {
  title: string;
  description: string;
  servings: number;
  prepTimeMinutes: number;
  difficulty: RecipeDifficulty;
  dietTags: string[];
  estimatedCostTotal: number;
  nutrition: {
    calories: number;
    proteinG: number;
    fatG: number;
    carbsG: number;
    fiberG: number;
    sugarG: number;
    sodiumMg: number;
  };
  instructions: string[];
  ingredients: SeedRecipeIngredient[];
}

const G = IngredientUnit.GRAMS;
const KG = IngredientUnit.KILOGRAMS;
const L = IngredientUnit.LITERS;
const UN = IngredientUnit.UNIT;

const seedRecipes: SeedRecipe[] = [
  {
    title: 'Milanesas de pollo con puré de papas',
    description:
      'El clásico de todas las casas: milanesas doradas y crocantes acompañadas de un puré cremoso.',
    servings: 4,
    prepTimeMinutes: 40,
    difficulty: RecipeDifficulty.MEDIUM,
    dietTags: [],
    estimatedCostTotal: 8000,
    nutrition: { calories: 620, proteinG: 40, fatG: 25, carbsG: 55, fiberG: 5, sugarG: 4, sodiumMg: 480 },
    instructions: [
      'Cortar la pechuga de pollo en filetes finos y salpimentar.',
      'Pasar cada filete por huevo batido y luego por pan rallado, presionando bien.',
      'Freír las milanesas en aceite caliente hasta dorar de ambos lados. Escurrir sobre papel absorbente.',
      'Pelar y hervir las papas en agua con sal hasta que estén tiernas.',
      'Hacer puré con las papas calientes, un chorrito de aceite y sal a gusto.',
      'Servir las milanesas junto al puré.',
    ],
    ingredients: [
      { ingredientName: 'Pollo (pechuga)', quantity: 0.6, unit: KG },
      { ingredientName: 'Huevo', quantity: 2, unit: UN },
      { ingredientName: 'Pan', quantity: 1, unit: UN, notes: 'rallado' },
      { ingredientName: 'Papa', quantity: 1, unit: KG },
      { ingredientName: 'Aceite', quantity: 0.2, unit: L },
      { ingredientName: 'Sal', quantity: 10, unit: G },
    ],
  },
  {
    title: 'Tortilla de papas y huevo',
    description: 'Tortilla española casera, jugosa por dentro y dorada por fuera.',
    servings: 4,
    prepTimeMinutes: 30,
    difficulty: RecipeDifficulty.MEDIUM,
    dietTags: ['vegetariano', 'economico'],
    estimatedCostTotal: 3500,
    nutrition: { calories: 320, proteinG: 14, fatG: 18, carbsG: 28, fiberG: 3, sugarG: 3, sodiumMg: 380 },
    instructions: [
      'Pelar y cortar las papas en rodajas finas. Cortar la cebolla en juliana.',
      'Freír las papas y la cebolla en aceite a fuego suave hasta que estén tiernas, sin dorar.',
      'Escurrir el exceso de aceite y mezclar con los huevos batidos y sal.',
      'Volcar todo en una sartén caliente y cocinar a fuego medio-bajo.',
      'Dar vuelta la tortilla con ayuda de un plato y cocinar del otro lado hasta que cuaje.',
    ],
    ingredients: [
      { ingredientName: 'Papa', quantity: 0.5, unit: KG },
      { ingredientName: 'Huevo', quantity: 6, unit: UN },
      { ingredientName: 'Cebolla', quantity: 1, unit: UN },
      { ingredientName: 'Aceite', quantity: 0.1, unit: L },
      { ingredientName: 'Sal', quantity: 5, unit: G },
    ],
  },
  {
    title: 'Arroz con pollo',
    description: 'Arroz sabroso cocido junto al pollo, morrón y cebolla en una sola olla.',
    servings: 4,
    prepTimeMinutes: 45,
    difficulty: RecipeDifficulty.MEDIUM,
    dietTags: [],
    estimatedCostTotal: 6000,
    nutrition: { calories: 480, proteinG: 32, fatG: 12, carbsG: 58, fiberG: 3, sugarG: 4, sodiumMg: 420 },
    instructions: [
      'Cortar el pollo en cubos y dorarlo en una olla con aceite. Reservar.',
      'En la misma olla, rehogar la cebolla, el morrón y el ajo picados.',
      'Agregar el arroz y mezclar un minuto para que tome sabor.',
      'Incorporar el pollo dorado y cubrir con agua caliente. Salar.',
      'Cocinar tapado a fuego bajo hasta que el arroz esté a punto, revolviendo de vez en cuando.',
    ],
    ingredients: [
      { ingredientName: 'Arroz', quantity: 0.3, unit: KG },
      { ingredientName: 'Pollo (pechuga)', quantity: 0.5, unit: KG },
      { ingredientName: 'Cebolla', quantity: 1, unit: UN },
      { ingredientName: 'Morrón', quantity: 1, unit: UN },
      { ingredientName: 'Ajo', quantity: 2, unit: UN },
      { ingredientName: 'Aceite', quantity: 0.05, unit: L },
      { ingredientName: 'Sal', quantity: 8, unit: G },
    ],
  },
  {
    title: 'Ensalada de lentejas',
    description: 'Fresca, económica y rendidora — ideal como plato principal liviano.',
    servings: 4,
    prepTimeMinutes: 25,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegetariano', 'vegano', 'economico'],
    estimatedCostTotal: 2500,
    nutrition: { calories: 280, proteinG: 15, fatG: 8, carbsG: 38, fiberG: 12, sugarG: 5, sodiumMg: 320 },
    instructions: [
      'Cocinar las lentejas en agua con sal hasta que estén tiernas. Escurrir y dejar enfriar.',
      'Cortar la cebolla y el tomate en cubos pequeños.',
      'Mezclar las lentejas con la cebolla, el tomate, aceite, sal y jugo de limón.',
      'Dejar reposar unos minutos en la heladera antes de servir.',
    ],
    ingredients: [
      { ingredientName: 'Lentejas', quantity: 0.3, unit: KG },
      { ingredientName: 'Cebolla', quantity: 1, unit: UN },
      { ingredientName: 'Tomate', quantity: 2, unit: UN },
      { ingredientName: 'Aceite', quantity: 0.03, unit: L },
      { ingredientName: 'Sal', quantity: 5, unit: G },
      { ingredientName: 'Limón', quantity: 1, unit: UN },
    ],
  },
  {
    title: 'Tarta de verduras',
    description: 'Tarta casera de morrón, cebolla y queso, ideal para el almuerzo o la cena.',
    servings: 6,
    prepTimeMinutes: 50,
    difficulty: RecipeDifficulty.MEDIUM,
    dietTags: ['vegetariano'],
    estimatedCostTotal: 4500,
    nutrition: { calories: 340, proteinG: 14, fatG: 20, carbsG: 26, fiberG: 3, sugarG: 4, sodiumMg: 400 },
    instructions: [
      'Mezclar la harina con aceite, sal y un poco de agua hasta formar una masa lisa. Dejar descansar.',
      'Estirar la masa y cubrir una tartera enmantecada.',
      'Rehogar la cebolla y el morrón cortados en aceite hasta que estén tiernos.',
      'Batir los huevos con la leche, mezclar con las verduras rehogadas y el queso en cubos.',
      'Volcar el relleno sobre la masa y hornear a fuego medio hasta que cuaje y dore, unos 30 minutos.',
    ],
    ingredients: [
      { ingredientName: 'Harina', quantity: 0.25, unit: KG },
      { ingredientName: 'Huevo', quantity: 3, unit: UN },
      { ingredientName: 'Morrón', quantity: 1, unit: UN },
      { ingredientName: 'Cebolla', quantity: 1, unit: UN },
      { ingredientName: 'Queso', quantity: 150, unit: G },
      { ingredientName: 'Leche', quantity: 0.1, unit: L },
      { ingredientName: 'Aceite', quantity: 0.02, unit: L },
      { ingredientName: 'Sal', quantity: 5, unit: G },
    ],
  },
  {
    title: 'Fideos con salsa de tomate y ajo',
    description: 'Un plato rápido, económico y de siempre: fideos con una salsa simple de tomate y ajo.',
    servings: 4,
    prepTimeMinutes: 25,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegetariano', 'vegano', 'economico'],
    estimatedCostTotal: 3000,
    nutrition: { calories: 410, proteinG: 12, fatG: 10, carbsG: 68, fiberG: 5, sugarG: 8, sodiumMg: 350 },
    instructions: [
      'Hervir los fideos en agua con sal según el tiempo indicado.',
      'Mientras tanto, rehogar el ajo y la cebolla picados en aceite a fuego suave.',
      'Agregar el tomate picado y cocinar hasta formar una salsa, salando a gusto.',
      'Escurrir los fideos y mezclar con la salsa antes de servir.',
    ],
    ingredients: [
      { ingredientName: 'Fideos', quantity: 0.4, unit: KG },
      { ingredientName: 'Tomate', quantity: 4, unit: UN },
      { ingredientName: 'Ajo', quantity: 3, unit: UN },
      { ingredientName: 'Cebolla', quantity: 1, unit: UN },
      { ingredientName: 'Aceite', quantity: 0.04, unit: L },
      { ingredientName: 'Sal', quantity: 6, unit: G },
    ],
  },
  {
    title: 'Ensalada César simple',
    description: 'Versión casera y sencilla de la clásica ensalada César con pollo.',
    servings: 2,
    prepTimeMinutes: 20,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['fitness'],
    estimatedCostTotal: 4000,
    nutrition: { calories: 350, proteinG: 30, fatG: 18, carbsG: 18, fiberG: 3, sugarG: 3, sodiumMg: 460 },
    instructions: [
      'Cocinar la pechuga de pollo a la plancha con sal y cortarla en tiras.',
      'Cortar el pan en cubos y tostarlo en una sartén con un poco de aceite hasta dorar (croutons).',
      'Lavar y cortar la lechuga en trozos grandes.',
      'Mezclar la lechuga con el pollo, los croutons y el queso en láminas.',
      'Aliñar con aceite, sal y jugo de limón antes de servir.',
    ],
    ingredients: [
      { ingredientName: 'Lechuga', quantity: 1, unit: UN },
      { ingredientName: 'Pollo (pechuga)', quantity: 0.3, unit: KG },
      { ingredientName: 'Queso', quantity: 50, unit: G },
      { ingredientName: 'Pan', quantity: 1, unit: UN },
      { ingredientName: 'Aceite', quantity: 0.03, unit: L },
      { ingredientName: 'Sal', quantity: 3, unit: G },
      { ingredientName: 'Limón', quantity: 1, unit: UN },
    ],
  },
  {
    title: 'Guiso de lentejas con carne',
    description: 'Guiso abundante y reconfortante, perfecto para los días fríos.',
    servings: 6,
    prepTimeMinutes: 60,
    difficulty: RecipeDifficulty.MEDIUM,
    dietTags: ['economico'],
    estimatedCostTotal: 5000,
    nutrition: { calories: 390, proteinG: 26, fatG: 15, carbsG: 34, fiberG: 10, sugarG: 4, sodiumMg: 410 },
    instructions: [
      'Rehogar la cebolla, el ajo y el morrón picados en una olla con aceite.',
      'Agregar la carne picada y cocinar hasta que pierda el color rosado.',
      'Incorporar la zanahoria en cubos y las lentejas, cubrir con agua y salar.',
      'Cocinar tapado a fuego medio-bajo hasta que las lentejas estén tiernas, revolviendo de vez en cuando.',
      'Ajustar la sal y dejar reposar unos minutos antes de servir.',
    ],
    ingredients: [
      { ingredientName: 'Lentejas', quantity: 0.3, unit: KG },
      { ingredientName: 'Carne picada', quantity: 0.4, unit: KG },
      { ingredientName: 'Cebolla', quantity: 1, unit: UN },
      { ingredientName: 'Zanahoria', quantity: 2, unit: UN },
      { ingredientName: 'Morrón', quantity: 1, unit: UN },
      { ingredientName: 'Ajo', quantity: 2, unit: UN },
      { ingredientName: 'Aceite', quantity: 0.03, unit: L },
      { ingredientName: 'Sal', quantity: 8, unit: G },
    ],
  },
  {
    title: 'Pescado al horno con papas y zanahoria',
    description: 'Pescado horneado con guarnición de papas y zanahorias, liviano y sabroso.',
    servings: 4,
    prepTimeMinutes: 45,
    difficulty: RecipeDifficulty.MEDIUM,
    dietTags: ['fitness'],
    estimatedCostTotal: 7000,
    nutrition: { calories: 380, proteinG: 32, fatG: 12, carbsG: 32, fiberG: 5, sugarG: 5, sodiumMg: 360 },
    instructions: [
      'Precalentar el horno y colocar el pescado en una fuente aceitada.',
      'Cortar las papas y zanahorias en rodajas y disponerlas alrededor del pescado.',
      'Agregar la cebolla y el ajo picados, un chorro de aceite, sal y jugo de limón por encima.',
      'Hornear hasta que el pescado esté cocido y las papas tiernas, unos 30-35 minutos.',
    ],
    ingredients: [
      { ingredientName: 'Pescado (filete)', quantity: 0.6, unit: KG },
      { ingredientName: 'Papa', quantity: 0.5, unit: KG },
      { ingredientName: 'Zanahoria', quantity: 0.4, unit: KG },
      { ingredientName: 'Cebolla', quantity: 1, unit: UN },
      { ingredientName: 'Ajo', quantity: 2, unit: UN },
      { ingredientName: 'Aceite', quantity: 0.04, unit: L },
      { ingredientName: 'Sal', quantity: 8, unit: G },
      { ingredientName: 'Limón', quantity: 1, unit: UN },
    ],
  },
  {
    title: 'Ensalada mixta de verduras',
    description: 'Ensalada fresca y simple para acompañar cualquier plato o comer sola.',
    servings: 4,
    prepTimeMinutes: 15,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegetariano', 'vegano', 'fitness', 'economico'],
    estimatedCostTotal: 1800,
    nutrition: { calories: 120, proteinG: 2, fatG: 8, carbsG: 12, fiberG: 4, sugarG: 6, sodiumMg: 180 },
    instructions: [
      'Lavar y cortar la lechuga en trozos. Cortar el tomate y la cebolla en rodajas finas.',
      'Rallar o cortar en bastones finos la zanahoria.',
      'Mezclar todas las verduras en una fuente.',
      'Aliñar con aceite, sal y jugo de limón antes de servir.',
    ],
    ingredients: [
      { ingredientName: 'Lechuga', quantity: 1, unit: UN },
      { ingredientName: 'Tomate', quantity: 3, unit: UN },
      { ingredientName: 'Cebolla', quantity: 1, unit: UN },
      { ingredientName: 'Zanahoria', quantity: 0.3, unit: KG },
      { ingredientName: 'Aceite', quantity: 0.03, unit: L },
      { ingredientName: 'Sal', quantity: 4, unit: G },
      { ingredientName: 'Limón', quantity: 1, unit: UN },
    ],
  },
  {
    title: 'Sopa de zanahoria',
    description: 'Sopa cremosa y reconfortante, ideal como entrada o plato liviano.',
    servings: 4,
    prepTimeMinutes: 35,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegetariano', 'vegano', 'economico'],
    estimatedCostTotal: 1500,
    nutrition: { calories: 110, proteinG: 2, fatG: 5, carbsG: 15, fiberG: 4, sugarG: 7, sodiumMg: 300 },
    instructions: [
      'Rehogar la cebolla y el ajo picados en una olla con aceite.',
      'Agregar la zanahoria cortada en rodajas y cubrir con agua.',
      'Cocinar hasta que la zanahoria esté muy tierna. Salar a gusto.',
      'Procesar todo hasta lograr una crema homogénea y servir caliente.',
    ],
    ingredients: [
      { ingredientName: 'Zanahoria', quantity: 0.5, unit: KG },
      { ingredientName: 'Cebolla', quantity: 1, unit: UN },
      { ingredientName: 'Ajo', quantity: 2, unit: UN },
      { ingredientName: 'Agua', quantity: 1, unit: L },
      { ingredientName: 'Aceite', quantity: 0.02, unit: L },
      { ingredientName: 'Sal', quantity: 6, unit: G },
    ],
  },
  {
    title: 'Panqueques caseros',
    description: 'Panqueques simples para el desayuno, la merienda o rellenos salados/dulces.',
    servings: 4,
    prepTimeMinutes: 25,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegetariano'],
    estimatedCostTotal: 2200,
    nutrition: { calories: 220, proteinG: 8, fatG: 9, carbsG: 27, fiberG: 1, sugarG: 3, sodiumMg: 150 },
    instructions: [
      'Batir los huevos con la leche hasta integrar.',
      'Incorporar la harina y la sal de a poco, mezclando para evitar grumos.',
      'Calentar una sartén con un poco de aceite y volcar un cucharón de la mezcla, esparciendo bien.',
      'Cocinar hasta que se despegue de los bordes, dar vuelta y cocinar unos segundos más del otro lado.',
      'Repetir con el resto de la mezcla.',
    ],
    ingredients: [
      { ingredientName: 'Harina', quantity: 0.2, unit: KG },
      { ingredientName: 'Huevo', quantity: 2, unit: UN },
      { ingredientName: 'Leche', quantity: 0.4, unit: L },
      { ingredientName: 'Aceite', quantity: 0.02, unit: L },
      { ingredientName: 'Sal', quantity: 2, unit: G },
    ],
  },
  {
    title: 'Sandwich de pollo y vegetales',
    description: 'Sandwich completo con pollo grillado, lechuga, tomate y queso.',
    servings: 2,
    prepTimeMinutes: 20,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['fitness'],
    estimatedCostTotal: 3800,
    nutrition: { calories: 420, proteinG: 34, fatG: 16, carbsG: 34, fiberG: 3, sugarG: 4, sodiumMg: 520 },
    instructions: [
      'Cocinar la pechuga de pollo a la plancha con sal hasta que esté bien cocida.',
      'Cortar el pan al medio y tostarlo levemente si se desea.',
      'Armar el sandwich con lechuga, tomate en rodajas, el pollo y el queso.',
      'Rociar con un hilo de aceite antes de cerrar el sandwich.',
    ],
    ingredients: [
      { ingredientName: 'Pan', quantity: 2, unit: UN },
      { ingredientName: 'Pollo (pechuga)', quantity: 0.25, unit: KG },
      { ingredientName: 'Lechuga', quantity: 1, unit: UN },
      { ingredientName: 'Tomate', quantity: 1, unit: UN },
      { ingredientName: 'Queso', quantity: 40, unit: G },
      { ingredientName: 'Aceite', quantity: 0.01, unit: L },
      { ingredientName: 'Sal', quantity: 3, unit: G },
    ],
  },
  {
    title: 'Ensalada de frutas con yogur',
    description: 'Postre fresco y liviano con manzana, banana y yogur.',
    servings: 2,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegetariano', 'fitness'],
    estimatedCostTotal: 1600,
    nutrition: { calories: 190, proteinG: 6, fatG: 3, carbsG: 38, fiberG: 4, sugarG: 28, sodiumMg: 60 },
    instructions: [
      'Cortar la manzana y la banana en cubos pequeños.',
      'Mezclar la fruta con unas gotas de jugo de limón para evitar que se oxide.',
      'Servir en copas o bowls y cubrir con el yogur.',
    ],
    ingredients: [
      { ingredientName: 'Manzana', quantity: 1, unit: UN },
      { ingredientName: 'Banana', quantity: 2, unit: UN },
      { ingredientName: 'Yogur', quantity: 2, unit: UN },
      { ingredientName: 'Limón', quantity: 1, unit: UN },
    ],
  },
  {
    title: 'Omelette de queso',
    description: 'Omelette simple y rápido, perfecto para un desayuno o cena liviana.',
    servings: 1,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegetariano', 'fitness', 'keto'],
    estimatedCostTotal: 1400,
    nutrition: { calories: 320, proteinG: 22, fatG: 25, carbsG: 3, fiberG: 0, sugarG: 1, sodiumMg: 380 },
    instructions: [
      'Batir los huevos con una pizca de sal.',
      'Calentar aceite en una sartén chica y volcar los huevos batidos.',
      'Cuando empiece a cuajar, agregar el queso en cubos o láminas sobre la mitad.',
      'Doblar el omelette al medio y cocinar unos segundos más antes de servir.',
    ],
    ingredients: [
      { ingredientName: 'Huevo', quantity: 3, unit: UN },
      { ingredientName: 'Queso', quantity: 40, unit: G },
      { ingredientName: 'Aceite', quantity: 0.01, unit: L },
      { ingredientName: 'Sal', quantity: 2, unit: G },
    ],
  },
  {
    title: 'Arroz con verduras salteadas',
    description: 'Arroz salteado con morrón, zanahoria y cebolla, colorido y rendidor.',
    servings: 4,
    prepTimeMinutes: 30,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegetariano', 'vegano', 'economico'],
    estimatedCostTotal: 2400,
    nutrition: { calories: 340, proteinG: 7, fatG: 9, carbsG: 58, fiberG: 4, sugarG: 5, sodiumMg: 320 },
    instructions: [
      'Cocinar el arroz en agua con sal hasta que esté a punto. Escurrir y reservar.',
      'Cortar el morrón, la zanahoria y la cebolla en cubos pequeños.',
      'Saltear las verduras con el ajo picado en aceite hasta que estén tiernas.',
      'Agregar el arroz cocido y saltear todo junto unos minutos, ajustando la sal.',
    ],
    ingredients: [
      { ingredientName: 'Arroz', quantity: 0.3, unit: KG },
      { ingredientName: 'Zanahoria', quantity: 0.3, unit: KG },
      { ingredientName: 'Morrón', quantity: 1, unit: UN },
      { ingredientName: 'Cebolla', quantity: 1, unit: UN },
      { ingredientName: 'Ajo', quantity: 2, unit: UN },
      { ingredientName: 'Aceite', quantity: 0.04, unit: L },
      { ingredientName: 'Sal', quantity: 6, unit: G },
    ],
  },
  {
    title: 'Energy balls crudas de dátil y cacao',
    description:
      'Bocaditos energéticos sin cocción, dulces por los dátiles y con el toque amargo del cacao.',
    servings: 8,
    prepTimeMinutes: 15,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegano', 'vegetariano', 'comida_cruda', 'economico'],
    estimatedCostTotal: 2800,
    nutrition: { calories: 140, proteinG: 3, fatG: 8, carbsG: 16, fiberG: 3, sugarG: 11, sodiumMg: 20 },
    instructions: [
      'Retirar los carozos a los dátiles si los tuvieran.',
      'Procesar los dátiles junto con las almendras hasta lograr una pasta pegajosa y homogénea.',
      'Agregar el cacao amargo y una pizca de sal, mezclar bien.',
      'Formar bolitas con las manos y pasarlas por coco rallado.',
      'Llevar a la heladera al menos 30 minutos antes de servir para que tomen firmeza.',
    ],
    ingredients: [
      { ingredientName: 'Dátiles', quantity: 200, unit: G },
      { ingredientName: 'Almendras', quantity: 100, unit: G },
      { ingredientName: 'Cacao amargo', quantity: 20, unit: G },
      { ingredientName: 'Coco rallado', quantity: 30, unit: G },
      { ingredientName: 'Sal', quantity: 1, unit: G },
    ],
  },
  {
    title: 'Leche de almendras casera',
    description: 'Bebida vegetal simple, sin cocción, para tomar sola o usar en otras recetas.',
    servings: 4,
    prepTimeMinutes: 15,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegano', 'vegetariano', 'comida_cruda'],
    estimatedCostTotal: 2200,
    nutrition: { calories: 90, proteinG: 3, fatG: 7, carbsG: 3, fiberG: 1, sugarG: 1, sodiumMg: 40 },
    instructions: [
      'Remojar las almendras en agua durante al menos 8 horas (o toda la noche) y luego escurrir.',
      'Licuar las almendras remojadas con el agua fresca durante un minuto, hasta que quede blanquecina.',
      'Colar con un lienzo o bolsa para leches vegetales, apretando bien para extraer todo el líquido.',
      'Agregar una pizca de sal, mezclar y guardar en la heladera hasta 3 días.',
    ],
    ingredients: [
      { ingredientName: 'Almendras', quantity: 150, unit: G },
      { ingredientName: 'Agua', quantity: 1, unit: L },
      { ingredientName: 'Sal', quantity: 1, unit: G },
    ],
  },
  {
    title: 'Ensalada crudivegana de zanahoria, manzana y limón',
    description: 'Ensalada fresca, rallada y sin cocción, ácida y crocante.',
    servings: 4,
    prepTimeMinutes: 15,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegano', 'vegetariano', 'comida_cruda', 'fitness'],
    estimatedCostTotal: 1600,
    nutrition: { calories: 100, proteinG: 1, fatG: 5, carbsG: 14, fiberG: 3, sugarG: 9, sodiumMg: 120 },
    instructions: [
      'Rallar la zanahoria y la manzana en tiras finas (con o sin cáscara la manzana, a gusto).',
      'Mezclar de inmediato con el jugo de limón para que la manzana no se oxide.',
      'Aliñar con aceite y una pizca de sal.',
      'Servir bien fría, apenas armada.',
    ],
    ingredients: [
      { ingredientName: 'Zanahoria', quantity: 0.3, unit: KG },
      { ingredientName: 'Manzana', quantity: 2, unit: UN },
      { ingredientName: 'Limón', quantity: 1, unit: UN },
      { ingredientName: 'Aceite', quantity: 0.02, unit: L },
      { ingredientName: 'Sal', quantity: 3, unit: G },
    ],
  },
  {
    title: 'Helado crudo de banana y cacao',
    description: '"Nice cream" cremoso hecho solo con banana congelada, sin heladera ni cocción.',
    servings: 3,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegano', 'vegetariano', 'comida_cruda', 'fitness'],
    estimatedCostTotal: 1400,
    nutrition: { calories: 150, proteinG: 2, fatG: 3, carbsG: 32, fiberG: 4, sugarG: 20, sodiumMg: 15 },
    instructions: [
      'Cortar las bananas maduras en rodajas y congelarlas al menos 4 horas (idealmente toda la noche).',
      'Procesar las rodajas congeladas hasta lograr una textura cremosa tipo helado, deteniéndose para raspar los bordes si hace falta.',
      'Agregar el cacao amargo y procesar unos segundos más para integrar.',
      'Servir enseguida con coco rallado por encima.',
    ],
    ingredients: [
      { ingredientName: 'Banana', quantity: 4, unit: UN },
      { ingredientName: 'Cacao amargo', quantity: 10, unit: G },
      { ingredientName: 'Coco rallado', quantity: 10, unit: G },
    ],
  },
  {
    title: 'Granola cruda de avena y semillas',
    description: 'Mezcla energética sin horno, lista en minutos, ideal para el desayuno con yogur o leche vegetal.',
    servings: 6,
    prepTimeMinutes: 15,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegano', 'vegetariano', 'comida_cruda'],
    estimatedCostTotal: 2600,
    nutrition: { calories: 210, proteinG: 6, fatG: 10, carbsG: 26, fiberG: 5, sugarG: 8, sodiumMg: 10 },
    instructions: [
      'Picar los dátiles y las almendras en trozos pequeños.',
      'Mezclar en un bol la avena, la chía, el coco rallado, los dátiles y las almendras picadas.',
      'Guardar en un frasco hermético a temperatura ambiente.',
      'Consumir con yogur, leche o leche vegetal y fruta fresca.',
    ],
    ingredients: [
      { ingredientName: 'Avena', quantity: 200, unit: G },
      { ingredientName: 'Almendras', quantity: 50, unit: G },
      { ingredientName: 'Chía', quantity: 20, unit: G },
      { ingredientName: 'Coco rallado', quantity: 30, unit: G },
      { ingredientName: 'Dátiles', quantity: 50, unit: G },
    ],
  },
  {
    title: 'Bowl crudo de manzana, chía y limón',
    description: 'Postre o desayuno liviano a base de gel de chía, manzana fresca y limón, sin cocción.',
    servings: 2,
    prepTimeMinutes: 10,
    difficulty: RecipeDifficulty.EASY,
    dietTags: ['vegano', 'vegetariano', 'comida_cruda', 'economico'],
    estimatedCostTotal: 900,
    nutrition: { calories: 130, proteinG: 3, fatG: 5, carbsG: 20, fiberG: 7, sugarG: 12, sodiumMg: 5 },
    instructions: [
      'Cortar la manzana en cubos pequeños o rallarla.',
      'Mezclar la manzana con la chía, el agua y el jugo de limón en un bowl.',
      'Dejar reposar en la heladera unos 15 minutos, hasta que la chía se hidrate y forme un gel.',
      'Servir bien frío, revolviendo antes de comer.',
    ],
    ingredients: [
      { ingredientName: 'Manzana', quantity: 2, unit: UN },
      { ingredientName: 'Chía', quantity: 20, unit: G },
      { ingredientName: 'Limón', quantity: 1, unit: UN },
      { ingredientName: 'Agua', quantity: 0.2, unit: L },
    ],
  },
];

async function run() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT ?? 5432),
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    entities: [path.join(__dirname, '../../modules/**/*.entity.{ts,js}')],
  });

  await dataSource.initialize();
  const ingredientsRepository = dataSource.getRepository(Ingredient);
  const recipesRepository = dataSource.getRepository(Recipe);

  let created = 0;
  let skipped = 0;

  for (const seed of seedRecipes) {
    const existing = await recipesRepository.findOne({
      where: { title: seed.title },
    });
    if (existing) {
      skipped++;
      continue;
    }

    const recipeIngredients = [];
    for (const ing of seed.ingredients) {
      const ingredient = await ingredientsRepository.findOne({
        where: { name: ILike(ing.ingredientName) },
      });
      if (!ingredient) {
        throw new Error(
          `Ingrediente "${ing.ingredientName}" no encontrado — corré primero el seed de ingredientes.`,
        );
      }
      recipeIngredients.push({
        ingredientId: ingredient.id,
        quantity: ing.quantity,
        unit: ing.unit,
        notes: ing.notes ?? null,
      });
    }

    const recipe = recipesRepository.create({
      title: seed.title,
      description: seed.description,
      instructions: seed.instructions.map((instruction, index) => ({
        order: index + 1,
        instruction,
      })),
      servings: seed.servings,
      prepTimeMinutes: seed.prepTimeMinutes,
      difficulty: seed.difficulty,
      estimatedCostTotal: seed.estimatedCostTotal,
      dietTags: seed.dietTags,
      isAiGenerated: false,
      createdByUserId: null,
      nutrition: seed.nutrition,
      recipeIngredients,
    });
    await recipesRepository.save(recipe);
    created++;
  }

  console.log(`Seed de recetas: ${created} creadas, ${skipped} ya existían.`);
  await dataSource.destroy();
}

run().catch((error) => {
  console.error('Error corriendo el seed:', error);
  process.exit(1);
});
