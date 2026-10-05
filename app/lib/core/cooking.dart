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
bool _sameDimension(String a, String b) =>
    a == b || ({'g', 'kg'}.containsAll({a, b})) || ({'ml', 'l'}.containsAll({a, b}));

/// Lo que falta de la receta según el inventario: lo que no está, o lo que
/// está en menor cantidad (convierte g↔kg y ml↔l). Si la unidad del inventario
/// no se puede comparar (ej. "unidad" contra gramos), se asume que alcanza.
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
    final comparable = owned.where((i) => _sameDimension(i.unit, ri.unit)).toList();
    if (comparable.isEmpty) continue; // no se puede comparar: se asume que alcanza
    double have = 0;
    for (final i in comparable) {
      have += i.unit == ri.unit ? i.quantity : i.quantity * _toBase[i.unit]! / _toBase[ri.unit]!;
    }
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
