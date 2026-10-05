import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/offline_recipes.dart';
import '../models/missing_ingredient.dart';
import '../models/paginated.dart';
import '../models/recipe.dart';
import '../core/i18n.dart';

class RecipesProvider extends ChangeNotifier {
  final _dio = ApiClient.instance.dio;

  List<Recipe> recipes = [];
  bool isLoading = false;
  String? errorMessage;
  int page = 1;
  int totalPages = 1;
  String search = '';
  String? dietTag;
  String ingredient = '';

  List<Recipe> favorites = [];
  bool isLoadingFavorites = false;

  /// Lista de ingredientes para el modo "¿qué puedo cocinar?"
  List<String> ingredients = [];

  Future<void> loadRecipes({bool reset = true}) async {
    if (reset) page = 1;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _dio.get('/recipes', queryParameters: {
        'page': page,
        'limit': 20,
        if (search.isNotEmpty) 'search': search,
        if (dietTag != null) 'dietTag': dietTag,
        if (ingredient.isNotEmpty) 'ingredient': ingredient,
        if (ingredients.isNotEmpty) 'ingredients': ingredients.join(','),
      });
      final paginated = Paginated<Recipe>.fromJson(
        response.data as Map<String, dynamic>,
        Recipe.fromJson,
      );
      recipes = reset ? paginated.items : [...recipes, ...paginated.items];
      totalPages = paginated.totalPages;
    } catch (_) {
      errorMessage = tr('No se pudieron cargar las recetas.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (page >= totalPages) return;
    page++;
    await loadRecipes(reset: false);
  }

  Future<Recipe> create({
    required String title,
    required String description,
    required List<String> instructions,
    required int servings,
    required int prepTimeMinutes,
    required String difficulty,
    double? estimatedCostTotal,
    required List<String> dietTags,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    final response = await _dio.post('/recipes', data: {
      'title': title,
      'description': description,
      'instructions': [
        for (var i = 0; i < instructions.length; i++)
          {'order': i + 1, 'instruction': instructions[i]},
      ],
      'servings': servings,
      'prepTimeMinutes': prepTimeMinutes,
      'difficulty': difficulty,
      'estimatedCostTotal': ?estimatedCostTotal,
      'dietTags': dietTags,
      'ingredients': ingredients,
    });
    return Recipe.fromJson(response.data as Map<String, dynamic>);
  }

  /// Sin internet, si la receta es favorita se devuelve la copia guardada.
  Future<Recipe> fetchOne(String id) async {
    try {
      final response = await _dio.get('/recipes/$id');
      final raw = response.data as Map<String, dynamic>;
      final recipe = Recipe.fromJson(raw);
      if (recipe.isFavorite) await OfflineRecipes.instance.saveRecipe(id, raw);
      return recipe;
    } catch (_) {
      final cached = await OfflineRecipes.instance.recipe(id);
      if (cached != null) return Recipe.fromJson(cached);
      rethrow;
    }
  }

  Future<Recipe> generateFromIngredients({
    required List<String> availableIngredients,
    List<String>? dietTags,
    int? maxPrepTimeMinutes,
    String? budget,
    int? servings,
    String? freeTextRequest,
  }) async {
    final response = await _dio.post('/ai/recipes/generate', data: {
      'availableIngredients': availableIngredients,
      if (dietTags != null && dietTags.isNotEmpty) 'dietTags': dietTags,
      'maxPrepTimeMinutes': ?maxPrepTimeMinutes,
      'budget': ?budget,
      'servings': ?servings,
      if (freeTextRequest != null && freeTextRequest.isNotEmpty)
        'freeTextRequest': freeTextRequest,
    });
    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception(tr('El servidor no pudo generar la receta. Verificá la conexión e intentá de nuevo.'));
    }
    return Recipe.fromJson(data);
  }

  Future<List<MissingIngredient>> cook(String recipeId,
      {double servingsMultiplier = 1}) async {
    final response = await _dio.post('/recipes/$recipeId/cook', data: {
      'servingsMultiplier': servingsMultiplier,
    });
    final missing = response.data['missingIngredients'] as List? ?? [];
    return missing
        .map((e) => MissingIngredient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> deleteRecipe(String recipeId) async {
    try {
      await _dio.delete('/recipes/$recipeId');
      recipes.removeWhere((r) => r.id == recipeId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFavorite(String recipeId) async {
    final response = await _dio.post('/recipes/$recipeId/favorite');
    final favorited = response.data['favorited'] as bool;
    if (favorited) {
      // guardar la receta completa para verla sin internet
      fetchOne(recipeId).ignore();
    } else {
      OfflineRecipes.instance.removeRecipe(recipeId).ignore();
    }
    final index = recipes.indexWhere((r) => r.id == recipeId);
    if (index != -1) {
      recipes[index].isFavorite = favorited;
      notifyListeners();
    }
    return favorited;
  }

  /// true cuando la lista de favoritas viene de la copia del celular.
  bool favoritesOffline = false;

  Future<void> loadFavorites() async {
    isLoadingFavorites = true;
    notifyListeners();
    try {
      final response = await _dio.get('/recipes/favorites');
      final rawList = response.data as List;
      favorites = rawList
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
      favoritesOffline = false;
      await OfflineRecipes.instance.saveFavoritesList(rawList);
      // completar en segundo plano las que todavía no están guardadas completas
      for (final r in favorites) {
        OfflineRecipes.instance.hasRecipe(r.id).then((has) {
          if (!has) fetchOne(r.id).ignore();
        });
      }
    } catch (_) {
      // sin internet: la copia guardada en el celular
      final cached = await OfflineRecipes.instance.favoritesList();
      if (cached != null) {
        favorites = cached.map(Recipe.fromJson).toList();
        favoritesOffline = true;
      }
    } finally {
      isLoadingFavorites = false;
      notifyListeners();
    }
  }
}
