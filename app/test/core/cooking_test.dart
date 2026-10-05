import 'package:chef_ai_app/core/cooking.dart';
import 'package:chef_ai_app/models/ingredient.dart';
import 'package:chef_ai_app/models/inventory_item.dart';
import 'package:chef_ai_app/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

Ingredient ing(String id) => Ingredient(id: id, name: id, category: 'otros', unit: 'g');

InventoryItem owned(String id, double qty, String unit) => InventoryItem(
      id: 'inv-$id',
      ingredientId: id,
      ingredient: ing(id),
      quantity: qty,
      unit: unit,
      state: 'fresh',
      source: 'manual',
    );

Recipe recipeWith(List<(String, double, String)> items) => Recipe(
      id: 'r',
      title: 'Receta',
      description: '',
      instructions: [],
      servings: 2,
      prepTimeMinutes: 20,
      difficulty: 'easy',
      dietTags: [],
      isAiGenerated: true,
      recipeIngredients: [
        for (final (id, q, u) in items)
          RecipeIngredientEntry(id: 'ri-$id', ingredient: ing(id), quantity: q, unit: u),
      ],
    );

void main() {
  group('parseStepMinutes', () {
    test('minutos, horas y rangos', () {
      expect(parseStepMinutes('Hervir los fideos 10 minutos.'), 10);
      expect(parseStepMinutes('Cocinar 8 a 10 min a fuego bajo'), 10);
      expect(parseStepMinutes('Hornear 1 hora'), 60);
      expect(parseStepMinutes('Dejar reposar 1,5 horas'), 90);
      expect(parseStepMinutes('Hornear 40-45 minutos'), 45);
    });
    test('sin tiempo: null', () {
      expect(parseStepMinutes('Picar la cebolla bien chiquita'), isNull);
      expect(parseStepMinutes('Agregar 2 huevos'), isNull);
    });
  });

  test('formatTimer', () {
    expect(formatTimer(const Duration(minutes: 9, seconds: 5)), '09:05');
    expect(formatTimer(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });

  group('missingFromInventory', () {
    test('falta lo que no está y la diferencia de lo que no alcanza', () {
      final recipe = recipeWith([
        ('fideos', 500, 'g'),
        ('tomate', 300, 'g'),
        ('leche', 500, 'ml'),
        ('huevos', 2, 'unidad'),
      ]);
      final missing = missingFromInventory(recipe, [
        owned('fideos', 0.2, 'kg'), // 200 g de 500 -> faltan 300 g
        owned('leche', 1, 'l'), // alcanza
        owned('huevos', 6, 'unidad'), // alcanza
      ]);
      expect(missing.map((m) => (m.name, m.quantity, m.unit)), [
        ('fideos', 300.0, 'g'),
        ('tomate', 300.0, 'g'),
      ]);
    });

    test('si las unidades no se pueden comparar, asume que alcanza', () {
      final recipe = recipeWith([('tomate', 300, 'g')]);
      expect(missingFromInventory(recipe, [owned('tomate', 1, 'unidad')]), isEmpty);
    });
  });
}
