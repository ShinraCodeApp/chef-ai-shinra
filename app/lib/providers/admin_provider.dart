import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/admin_stats.dart';
import '../models/ingredient.dart';
import '../models/paginated.dart';
import '../models/user.dart';

class AdminProvider extends ChangeNotifier {
  final _dio = ApiClient.instance.dio;

  AdminStats? stats;
  bool isLoadingStats = false;

  List<User> users = [];
  int page = 1;
  int totalPages = 1;
  bool isLoadingUsers = false;

  List<Ingredient> ingredients = [];
  int ingredientsPage = 1;
  int ingredientsTotalPages = 1;
  bool isLoadingIngredients = false;
  String ingredientsSearch = '';

  Future<void> loadStats() async {
    isLoadingStats = true;
    notifyListeners();
    try {
      final response = await _dio.get('/admin/stats');
      stats = AdminStats.fromJson(response.data as Map<String, dynamic>);
    } finally {
      isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({bool reset = true}) async {
    if (reset) page = 1;
    isLoadingUsers = true;
    notifyListeners();
    try {
      final response = await _dio.get('/admin/users', queryParameters: {
        'page': page,
        'limit': 20,
      });
      final paginated = Paginated<User>.fromJson(
        response.data as Map<String, dynamic>,
        User.fromJson,
      );
      users = reset ? paginated.items : [...users, ...paginated.items];
      totalPages = paginated.totalPages;
    } finally {
      isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> loadNextUsersPage() async {
    if (page >= totalPages) return;
    page++;
    await loadUsers(reset: false);
  }

  Future<bool> updateUserRole(String userId, String role) async {
    try {
      final response =
          await _dio.patch('/admin/users/$userId/role', data: {'role': role});
      final updated = User.fromJson(response.data as Map<String, dynamic>);
      final index = users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        users[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _dio.delete('/admin/users/$userId');
      users.removeWhere((u) => u.id == userId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadIngredients({bool reset = true}) async {
    if (reset) ingredientsPage = 1;
    isLoadingIngredients = true;
    notifyListeners();
    try {
      final response = await _dio.get('/ingredients', queryParameters: {
        'page': ingredientsPage,
        'limit': 20,
        if (ingredientsSearch.isNotEmpty) 'search': ingredientsSearch,
      });
      final paginated = Paginated<Ingredient>.fromJson(
        response.data as Map<String, dynamic>,
        Ingredient.fromJson,
      );
      ingredients = reset ? paginated.items : [...ingredients, ...paginated.items];
      ingredientsTotalPages = paginated.totalPages;
    } finally {
      isLoadingIngredients = false;
      notifyListeners();
    }
  }

  Future<void> loadNextIngredientsPage() async {
    if (ingredientsPage >= ingredientsTotalPages) return;
    ingredientsPage++;
    await loadIngredients(reset: false);
  }

  Future<bool> createIngredient(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/ingredients', data: data);
      ingredients = [Ingredient.fromJson(response.data as Map<String, dynamic>), ...ingredients];
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateIngredient(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/ingredients/$id', data: data);
      final updated = Ingredient.fromJson(response.data as Map<String, dynamic>);
      final index = ingredients.indexWhere((i) => i.id == id);
      if (index != -1) {
        ingredients[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteIngredient(String id) async {
    try {
      await _dio.delete('/ingredients/$id');
      ingredients.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
