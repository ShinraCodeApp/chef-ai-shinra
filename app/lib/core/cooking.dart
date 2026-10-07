import '../models/inventory_item.dart';
import '../models/missing_ingredient.dart';
import '../models/recipe.dart';

/// Minutos que pide un paso ("hervir 10 minutos", "hornear 1 hora",
/// "cocinar 8 a 10 min") para ofrecer un temporizador. Si da un rango, toma el
/// mayor. null si el paso no menciona un tiempo.
int? parseStepMinutes(String instruction) {
  final text = instruction.toLowerCase();
  final match = RegExp(
    r'(\d+(?:[.,]\d+)?)(?:\s*(?:a|-|o)\s*(\d+(?:[.,]\d+)?))?\s*(horas?|hs?\b|minutos?|mins?\b)',
  ).firstMatch(text);
  if (match == null) return null;
  final first = double.parse(match.group(1)!.replaceAll(',', '.'));
  final second = match.group(2) == null ? null : double.parse(match.group(2)!.replaceAll(',', '.'));
  final value = second != null && second > first ? second : first;
  final isHours = match.group(3)!.startsWith('h');
  final minutes = (isHours ? value * 60 : value).round();
  return minutes > 0 ? minutes : null;
}

String formatTimer(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

const _toBase = {'g': 1.0, 'kg': 1000.0, 'ml': 1.0, 'l': 1000.0};

/// Convierte [quantity] de [from] a [to]. Entre g/kg y ml/l es exacto; entre
/// "unidad" y peso/volumen usa [unitWeightG] (cuánto pesa una unidad, ej.
/// huevo ≈ 50 g; para líquidos 1 ml ≈ 1 g). null si no se puede convertir.
double? convertUnits(double quantity, String from, String to, {double? unitWeightG}) {
  if (from == to) return quantity;
  final sameScale =
      ({'g', 'kg'}.containsAll({from, to})) || ({'ml', 'l'}.containsAll({from, to}));
  if (sameScale) return quantity * _toBase[from]! / _toBase[to]!;
  if (unitWeightG != null && unitWeightG > 0) {
    if (from == 'unidad' && _toBase.containsKey(to)) return quantity * unitWeightG / _toBase[to]!;
    if (to == 'unidad' && _toBase.containsKey(from)) return quantity * _toBase[from]! / unitWeightG;
  }
  return null;
}

/// Lo que falta de la receta según el inventario: lo que no está, o lo que
/// está en menor cantidad. Convierte g↔kg, ml↔l y "unidad"↔gramos con el peso
/// promedio de una unidad (3 cebollas ≈ 450 g). Si igual no se puede comparar,
/// se asume que alcanza.
List<MissingIngredient> missingFromInventory(Recipe recipe, List<InventoryItem> inventory) {
  final missing = <MissingIngredient>[];
  for (final ri in recipe.recipeIngredients) {
    final owned = inventory.where((i) => i.ingredientId == ri.ingredient.id).toList();
    if (owned.isEmpty) {
      missing.add(MissingIngredient(
        ingredientId: ri.ingredient.id,
        name: ri.ingredient.name,
        quantity: ri.quantity,
        unit: ri.unit,
      ));
      continue;
    }
    final weight = ri.ingredient.unitWeightG;
    final converted = owned
        .map((i) => convertUnits(i.quantity, i.unit, ri.unit, unitWeightG: weight))
        .whereType<double>()
        .toList();
    if (converted.isEmpty) continue; // no se puede comparar: se asume que alcanza
    final have = converted.fold<double>(0, (a, b) => a + b);
    if (have + 1e-9 < ri.quantity) {
      missing.add(MissingIngredient(
        ingredientId: ri.ingredient.id,
        name: ri.ingredient.name,
        quantity: double.parse((ri.quantity - have).toStringAsFixed(2)),
        unit: ri.unit,
      ));
    }
  }
  return missing;
}
