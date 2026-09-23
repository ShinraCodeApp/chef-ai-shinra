import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/missing_ingredient.dart';
import '../models/paginated.dart';
import '../models/recipe.dart';

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
      });
      final paginated = Paginated<Recipe>.fromJson(
        response.data as Map<String, dynamic>,
        Recipe.fromJson,
      );
      recipes = reset ? paginated.items : [...recipes, ...paginated.items];
      totalPages = paginated.totalPages;
    } catch (_) {
      errorMessage = 'No se pudieron cargar las recetas.';
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
      if (estimatedCostTotal != null) 'estimatedCostTotal': estimatedCostTotal,
      'dietTags': dietTags,
      'ingredients': ingredients,
    });
    return Recipe.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Recipe> fetchOne(String id) async {
    final response = await _dio.get('/recipes/$id');
    return Recipe.fromJson(response.data as Map<String, dynamic>);
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
      if (maxPrepTimeMinutes != null) 'maxPrepTimeMinutes': maxPrepTimeMinutes,
      if (budget != null) 'budget': budget,
      if (servings != null) 'servings': servings,
      if (freeTextRequest != null && freeTextRequest.isNotEmpty)
        'freeTextRequest': freeTextRequest,
    });
    return Recipe.fromJson(response.data as Map<String, dynamic>);
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
    final index = recipes.indexWhere((r) => r.id == recipeId);
    if (index != -1) {
      recipes[index].isFavorite = favorited;
      notifyListeners();
    }
    return favorited;
  }

  Future<void> loadFavorites() async {
    isLoadingFavorites = true;
    notifyListeners();
    try {
      final response = await _dio.get('/recipes/favorites');
      favorites = (response.data as List)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    } finally {
      isLoadingFavorites = false;
      notifyListeners();
    }
  }
}
