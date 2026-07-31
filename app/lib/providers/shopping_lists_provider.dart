import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/shopping_list.dart';

class ShoppingListsProvider extends ChangeNotifier {
  final _dio = ApiClient.instance.dio;

  List<ShoppingList> lists = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _dio.get('/shopping-lists');
      lists = (response.data as List)
          .map((e) => ShoppingList.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      errorMessage = 'No se pudieron cargar las listas de compras.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ShoppingList?> generateFromMealPlan(String mealPlanId) async {
    try {
      final response = await _dio.post('/shopping-lists/generate-from-meal-plan',
          data: {'mealPlanId': mealPlanId});
      final list = ShoppingList.fromJson(response.data as Map<String, dynamic>);
      lists = [list, ...lists];
      notifyListeners();
      return list;
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleItem(String listId, String itemId) async {
    await _dio.post('/shopping-lists/$listId/items/$itemId/toggle');
    final list = lists.firstWhere((l) => l.id == listId);
    final item = list.items.firstWhere((i) => i.id == itemId);
    item.isChecked = !item.isChecked;
    notifyListeners();
  }

  Future<void> removeItem(String listId, String itemId) async {
    await _dio.delete('/shopping-lists/$listId/items/$itemId');
    final list = lists.firstWhere((l) => l.id == listId);
    list.items.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }
}
