import 'package:chef_ai_app/core/offline_recipes.dart';
import 'package:chef_ai_app/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> rawRecipe(String id) => {
      'id': id,
      'title': 'Fideos con tuco',
      'description': 'Clásico',
      'instructions': [
        {'order': 1, 'instruction': 'Hervir 10 minutos'},
      ],
      'servings': 2,
      'prepTimeMinutes': 20,
      'difficulty': 'easy',
      'dietTags': ['economico'],
      'isFavorite': true,
      'recipeIngredients': [
        {
          'id': 'ri1',
          'quantity': 500,
          'unit': 'g',
          'ingredient': {'id': 'fideos', 'name': 'Fideos', 'category': 'otros', 'unit': 'g'},
        },
      ],
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('guarda y recupera la lista y la receta completa', () async {
    final store = OfflineRecipes.instance;
    expect(await store.favoritesList(), isNull);

    await store.saveFavoritesList([rawRecipe('r1')]);
    await store.saveRecipe('r1', rawRecipe('r1'));

    final list = await store.favoritesList();
    expect(list!.map(Recipe.fromJson).single.title, 'Fideos con tuco');
    final full = Recipe.fromJson((await store.recipe('r1'))!);
    expect(full.recipeIngredients.single.ingredient.name, 'Fideos');
    expect(full.instructions.single.instruction, 'Hervir 10 minutos');
  });

  test('al sacar de favoritas se borra la copia', () async {
    final store = OfflineRecipes.instance;
    await store.saveRecipe('r1', rawRecipe('r1'));
    expect(await store.hasRecipe('r1'), isTrue);
    await store.removeRecipe('r1');
    expect(await store.hasRecipe('r1'), isFalse);
    expect(await store.recipe('r1'), isNull);
  });
}
