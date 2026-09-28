import '../models/recipe.dart';

/// Una condición de salud en la que la receta puede ayudar, con el motivo
/// que se muestra al pie del detalle de la receta.
class HealthCondition {
  final String name;
  final String reason;

  const HealthCondition(this.name, this.reason);
}

// Listas de ingredientes del catálogo (mismos nombres que ingredients.seed.ts).
// Las de tiroides se repiten en backend/src/database/seeds/health-tags.ts: si se
// cambian acá, cambiarlas también allá para que coincidan las etiquetas.
const _seafood = {
  'Pescado (filete)', 'Atún', 'Salmón', 'Camarones', 'Mejillones', 'Calamares',
  'Sardinas', 'Merluza', 'Caballa', 'Bacalao', 'Pulpo', 'Vieiras', 'Sepia',
  'Pez espada', 'Centolla', 'Anchoas', 'Kanikama', 'Alga nori',
};
const _oilyFish = {'Salmón', 'Sardinas', 'Caballa', 'Atún', 'Anchoas'};
const _dairy = {
  'Leche', 'Queso', 'Yogur', 'Yogur griego', 'Mozzarella', 'Ricota',
  'Queso crema', 'Burrata', 'Crema de leche', 'Manteca', 'Dulce de leche',
  'Leche condensada', 'Leche evaporada', 'Helado', 'Chocolate blanco',
};
const _calciumDairy = {
  'Leche', 'Queso', 'Yogur', 'Yogur griego', 'Mozzarella', 'Ricota', 'Burrata',
};
const _heartFriendly = {
  'Salmón', 'Sardinas', 'Caballa', 'Atún', 'Avena', 'Lentejas', 'Garbanzos',
  'Porotos negros', 'Nueces', 'Almendras', 'Linaza', 'Chía', 'Palta',
};
const _saturatedFat = {
  'Manteca', 'Panceta', 'Chorizo', 'Crema de leche', 'Manteca de cerdo',
  'Morcilla', 'Chinchulines', 'Mollejas', 'Riñones', 'Dulce de leche',
  'Leche condensada', 'Salchichas', 'Mortadela', 'Cochinillo',
};
const _ironRich = {
  'Carne (bife)', 'Carne picada', 'Lentejas', 'Garbanzos', 'Porotos negros',
  'Mejillones', 'Riñones', 'Morcilla', 'Cordero',
};

// Mismo criterio que withHealthTags en backend/src/database/seeds/health-tags.ts.
const _meatOrFish = {
  ..._seafood,
  'Pollo (pechuga)', 'Carne picada', 'Carne (bife)', 'Costillas de cerdo',
  'Cerdo (magro)', 'Chorizo', 'Jamón', 'Manteca de cerdo', 'Charque', 'Panceta',
  'Salchichas', 'Cochinillo', 'Manitas de cerdo', 'Chinchulines', 'Riñones',
  'Morcilla', 'Pularda', 'Pavo', 'Mollejas', 'Mortadela', 'Conejo', 'Cordero',
  'Salsa de pescado', 'Salsa de ostión', 'Salsa inglesa', 'Gelatina sin sabor',
  'Malvaviscos',
};
const _eggDairyHoney = {..._dairy, 'Huevo', 'Mayonesa', 'Miel'};
const _ambiguous = {'Caldo', 'Proteína en polvo', 'Galletas'};

/// Deduce, a partir de las etiquetas, los ingredientes y la nutrición por
/// porción, en qué condiciones de salud puede ayudar la receta. Es información
/// orientativa (el detalle lo aclara): no reemplaza la indicación médica.
List<HealthCondition> healthConditionsFor(Recipe recipe) {
  final tags = recipe.dietTags.toSet();
  final names = recipe.recipeIngredients.map((ri) => ri.ingredient.name).toSet();
  final hasWholeEgg = recipe.recipeIngredients.any((ri) =>
      ri.ingredient.name == 'Huevo' &&
      !(ri.notes ?? '').toLowerCase().contains('clara'));
  final lowIodine = tags.contains('bajo_yodo');
  final n = recipe.nutrition;
  final result = <HealthCondition>[];

  // Dietas: si un ingrediente es claramente de origen animal se descarta, aunque
  // la receta venga etiquetada; si hay alguno dudoso (caldo, proteína en polvo,
  // galletitas) se confía en la etiqueta.
  bool isPlantSyrup(RecipeIngredientEntry ri) =>
      ri.ingredient.name == 'Miel' &&
      RegExp('arce|agave', caseSensitive: false).hasMatch(ri.notes ?? '');
  final ingredientsKnown = recipe.recipeIngredients.isNotEmpty;
  final hasMeat = names.any(_meatOrFish.contains);
  final hasAnimalProduct = recipe.recipeIngredients.any((ri) =>
      _eggDairyHoney.contains(ri.ingredient.name) && !isPlantSyrup(ri));
  final hasAmbiguous = recipe.recipeIngredients.any((ri) =>
      _ambiguous.contains(ri.ingredient.name) &&
      !(ri.ingredient.name == 'Caldo' &&
          (ri.notes ?? '').toLowerCase().contains('verdura')));
  final vegan = ingredientsKnown &&
      !hasMeat &&
      !hasAnimalProduct &&
      (!hasAmbiguous || tags.contains('vegano'));
  final vegetarian = !vegan &&
      ingredientsKnown &&
      !hasMeat &&
      (!hasAmbiguous ||
          tags.contains('vegetariano') ||
          tags.contains('vegano'));
  if (vegan) {
    result.add(const HealthCondition('Dieta vegana',
        'No lleva carne, pescado, huevo, lácteos ni miel. Conviene combinar legumbres, cereales y frutos secos para completar la proteína.'));
  } else if (vegetarian) {
    result.add(const HealthCondition('Dieta vegetariana',
        'No lleva carne ni pescado (puede llevar huevo, lácteos o miel).'));
  }

  if (!lowIodine &&
      (tags.contains('hipotiroidismo') ||
          names.any(_seafood.contains) ||
          hasWholeEgg)) {
    result.add(const HealthCondition('Hipotiroidismo',
        'Aporta yodo y selenio (pescados, mariscos, algas o huevo), nutrientes que la tiroides necesita para producir hormona.'));
  }
  if (lowIodine) {
    result.add(const HealthCondition(
        'Cáncer de tiroides (preparación para yodo radiactivo)',
        'Es baja en yodo: sirve para la dieta de 1 a 2 semanas previa al tratamiento con yodo radiactivo o a un rastreo corporal.'));
  }
  if (lowIodine || tags.contains('hipertiroidismo')) {
    result.add(const HealthCondition('Hipertiroidismo',
        'No suma yodo extra, útil cuando el médico indica moderar su consumo.'));
  }
  if (tags.contains('sin_tacc')) {
    result.add(const HealthCondition(
        'Celiaquía', 'No lleva trigo, avena, cebada ni centeno (TACC).'));
  }
  if (names.isNotEmpty && !names.any(_dairy.contains)) {
    result.add(const HealthCondition(
        'Intolerancia a la lactosa', 'No lleva leche ni derivados lácteos.'));
  }
  if (n != null) {
    if (n.carbsG <= 20 && n.sugarG <= 10) {
      result.add(const HealthCondition('Diabetes y resistencia a la insulina',
          'Baja en carbohidratos y azúcares por porción, ayuda a evitar picos de glucosa.'));
    }
    if (n.sodiumMg <= 300) {
      result.add(const HealthCondition('Hipertensión',
          'Baja en sodio por porción (300 mg o menos).'));
    }
    if (names.any(_heartFriendly.contains) &&
        !names.any(_saturatedFat.contains) &&
        n.fatG <= 25) {
      result.add(HealthCondition('Colesterol alto y salud del corazón',
          names.any(_oilyFish.contains)
              ? 'Aporta omega 3 de pescado azul y pocas grasas saturadas.'
              : 'Aporta fibra soluble o grasas saludables (avena, legumbres, frutos secos, semillas o palta) y pocas grasas saturadas.'));
    }
    if (n.fiberG >= 6) {
      result.add(const HealthCondition('Estreñimiento',
          'Rica en fibra (6 g o más por porción), favorece el tránsito intestinal.'));
    }
    if (n.calories > 0 && n.calories <= 350 && n.proteinG >= 15) {
      result.add(const HealthCondition('Sobrepeso',
          'Moderada en calorías y con buena proteína, lo que ayuda a la saciedad.'));
    }
  }
  if (names.any(_ironRich.contains)) {
    result.add(const HealthCondition('Anemia por falta de hierro',
        'Aporta hierro (carnes rojas, legumbres o mariscos); acompañar con limón, morrón o tomate mejora su absorción.'));
  }
  if (names.any(_calciumDairy.contains) || names.contains('Sardinas')) {
    result.add(const HealthCondition(
        'Osteoporosis', 'Aporta calcio (lácteos o sardinas) para los huesos.'));
  }
  return result;
}
