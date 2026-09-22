import '../models/ingredient.dart';

/// Convierte una cantidad de un ítem a gramos para poder aplicar los valores
/// nutricionales del ingrediente (que están expresados "por cada 100g").
/// Para líquidos se asume 1ml ~ 1g (aproximación estándar en etiquetado
/// nutricional). Para "unidad" no hay forma de convertir sin saber el peso
/// de una unidad, así que devuelve null.
double? gramsForQuantity(double quantity, String unit) {
  switch (unit) {
    case 'g':
      return quantity;
    case 'kg':
      return quantity * 1000;
    case 'ml':
      return quantity;
    case 'l':
      return quantity * 1000;
    default:
      return null;
  }
}

class ItemNutrition {
  final double? calories;
  final double? proteinG;
  final double? carbsG;

  const ItemNutrition({this.calories, this.proteinG, this.carbsG});

  bool get hasData => calories != null || proteinG != null || carbsG != null;
}

/// Calcula calorías/proteína/carbohidratos totales para la cantidad cargada de
/// un ingrediente, a partir de sus valores "por cada 100g".
ItemNutrition nutritionFor(Ingredient ingredient, double quantity, String unit) {
  final grams = gramsForQuantity(quantity, unit);
  if (grams == null) return const ItemNutrition();
  double? scale(double? per100g) => per100g == null ? null : per100g * grams / 100;
  return ItemNutrition(
    calories: scale(ingredient.caloriesPer100g),
    proteinG: scale(ingredient.proteinPer100g),
    carbsG: scale(ingredient.carbsPer100g),
  );
}

/// Clasifica un ingrediente como "proteico" o "carbohidratos" según cuál de
/// los dos macronutrientes predomina cada 100g. Devuelve null si no hay datos
/// suficientes o si ninguno de los dos predomina claramente (ej. condimentos).
String? macroLabel(Ingredient ingredient) {
  final protein = ingredient.proteinPer100g;
  final carbs = ingredient.carbsPer100g;
  if (protein == null || carbs == null) return null;
  if (protein < 1 && carbs < 1) return null;
  if (protein > carbs) return 'Proteico';
  if (carbs > protein) return 'Carbohidratos';
  return null;
}
