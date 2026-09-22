/// Mapa de recetas del catálogo base -> foto local curada a mano, para no depender
/// de imágenes de stock genéricas (que muchas veces no corresponden al plato real).
/// Las fotos viven en assets/recipe_images/ (declaradas en pubspec.yaml).
/// La clave es el título EXACTO de la receta tal como está en recipes.seed.ts.
const Map<String, String> kRecipeImageAssets = {
  'Milanesas de pollo con puré de papas': 'assets/recipe_images/milanesas-pollo-pure-papas.jpg',
  'Tortilla de papas y huevo': 'assets/recipe_images/tortilla-papas-huevo.jpg',
  'Arroz con pollo': 'assets/recipe_images/arroz-con-pollo.jpg',
  'Ensalada de lentejas': 'assets/recipe_images/ensalada-lentejas.jpg',
  'Tarta de verduras': 'assets/recipe_images/tarta-verduras.jpg',
  'Fideos con salsa de tomate y ajo': 'assets/recipe_images/fideos-tomate-ajo.jpg',
  'Ensalada César simple': 'assets/recipe_images/ensalada-cesar.jpg',
  'Guiso de lentejas con carne': 'assets/recipe_images/guiso-lentejas-carne.jpg',
  'Pescado al horno con papas y zanahoria': 'assets/recipe_images/pescado-horno-papas-zanahoria.jpg',
  'Ensalada mixta de verduras': 'assets/recipe_images/ensalada-mixta-verduras.jpg',
  'Sopa de zanahoria': 'assets/recipe_images/sopa-zanahoria.jpg',
  'Panqueques caseros': 'assets/recipe_images/panqueques-caseros.jpg',
  'Sandwich de pollo y vegetales': 'assets/recipe_images/sandwich-pollo-vegetales.jpg',
  'Ensalada de frutas con yogur': 'assets/recipe_images/ensalada-frutas-yogur.jpg',
  'Omelette de queso': 'assets/recipe_images/omelette-queso.jpg',
  'Arroz con verduras salteadas': 'assets/recipe_images/arroz-verduras-salteadas.jpg',
  'Energy balls crudas de dátil y cacao': 'assets/recipe_images/energy-balls-datil-cacao.jpg',
  'Leche de almendras casera': 'assets/recipe_images/leche-almendras.jpg',
  'Ensalada crudivegana de zanahoria, manzana y limón':
      'assets/recipe_images/ensalada-crudivegana-zanahoria-manzana-limon.jpg',
  'Helado crudo de banana y cacao': 'assets/recipe_images/helado-banana-cacao.jpg',
  'Granola cruda de avena y semillas': 'assets/recipe_images/granola-avena-semillas.jpg',
  'Bowl crudo de manzana, chía y limón': 'assets/recipe_images/bowl-manzana-chia-limon.jpg',
  'Pollo a la mostaza': 'assets/recipe_images/pollo-mostaza.jpg',
  'Pollo al curry': 'assets/recipe_images/pollo-curry.jpg',
  'Pizza de pollo': 'assets/recipe_images/pizza-pollo.jpg',
  'Pollo al limón y ajo': 'assets/recipe_images/pollo-limon-ajo.jpg',
  'Pollo crocante con yogur y semillas': 'assets/recipe_images/pollo-crocante-yogur-semillas.jpg',
  'Milanesas de berenjena al horno': 'assets/recipe_images/milanesas-berenjena.jpg',
  'Guacamole casero': 'assets/recipe_images/guacamole.jpg',
  'Ensalada de garbanzos con verduras': 'assets/recipe_images/ensalada-garbanzos.jpg',
  'Tarta de atún y verduras': 'assets/recipe_images/tarta-atun-verduras.jpg',
  'Batatas al horno con especias': 'assets/recipe_images/batatas-horno-especias.jpg',
  'Crema de calabaza': 'assets/recipe_images/crema-calabaza.jpg',
  'Buñuelos de acelga': 'assets/recipe_images/bunuelos-acelga.jpg',
  'Bife a la plancha con batatas al horno': 'assets/recipe_images/bife-plancha-batatas.jpg',
  'Bowl de yogur, granola y banana': 'assets/recipe_images/bowl-yogur-granola-banana.jpg',
  'Wrap de pollo, palta y vegetales': 'assets/recipe_images/wrap-pollo-palta.jpg',
  'Bowl de atún, huevo y almendras': 'assets/recipe_images/bowl-atun-huevo-almendras.jpg',
  'Tostadas de atún, huevo y queso': 'assets/recipe_images/tostadas-atun-huevo-queso.jpg',
  'Ensalada de brócoli y coliflor con queso':
      'assets/recipe_images/ensalada-brocoli-coliflor-queso.jpg',
  'Bife con brócoli y batatas al horno': 'assets/recipe_images/bife-brocoli-batatas.jpg',
  'Sándwich de pepino y pollo': 'assets/recipe_images/sandwich-pepino-pollo.jpg',
};

/// Devuelve la ruta del asset local para una receta del catálogo base, o null si
/// no hay una foto curada para ese título (recetas creadas por usuarios o IA).
String? localRecipeImageAsset(String title) => kRecipeImageAssets[title];
