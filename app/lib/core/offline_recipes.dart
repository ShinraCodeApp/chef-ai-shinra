import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Copia local de las recetas favoritas para verlas sin internet: la lista y
/// cada receta completa (ingredientes y pasos), tal como las devuelve la API.
class OfflineRecipes {
  OfflineRecipes._();
  static final instance = OfflineRecipes._();

  static const _listKey = 'offline_favorites_list';
  static String _recipeKey(String id) => 'offline_recipe_$id';

  Future<void> saveFavoritesList(List<dynamic> rawList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listKey, jsonEncode(rawList));
  }

  Future<List<Map<String, dynamic>>?> favoritesList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_listKey);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveRecipe(String id, Map<String, dynamic> rawRecipe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recipeKey(id), jsonEncode(rawRecipe));
  }

  Future<Map<String, dynamic>?> recipe(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recipeKey(id));
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<bool> hasRecipe(String id) async =>
      (await SharedPreferences.getInstance()).containsKey(_recipeKey(id));

  Future<void> removeRecipe(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recipeKey(id));
  }
}
