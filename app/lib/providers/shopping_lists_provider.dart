import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/missing_ingredient.dart';
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

  /// Agrega ingredientes que faltaron al cocinar una receta a una lista de compras:
  /// reutiliza la más reciente si ya existe alguna, o crea "Para comprar" si no.
  Future<bool> addMissingItems(List<MissingIngredient> items) async {
    try {
      if (lists.isEmpty) {
        await load();
      }
      var targetListId = lists.isNotEmpty ? lists.first.id : null;
      if (targetListId == null) {
        final response =
            await _dio.post('/shopping-lists', data: {'name': 'Para comprar'});
        final created = ShoppingList.fromJson(response.data as Map<String, dynamic>);
        lists = [created, ...lists];
        targetListId = created.id;
      }
      for (final item in items) {
        await _dio.post('/shopping-lists/$targetListId/items', data: {
          'ingredientId': item.ingredientId,
          'quantity': item.quantity,
          'unit': item.unit,
        });
      }
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createList(String name) async {
    try {
      final response = await _dio.post('/shopping-lists', data: {'name': name});
      final created = ShoppingList.fromJson(response.data as Map<String, dynamic>);
      lists = [created, ...lists];
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addCustomItem(
    String listId, {
    required String name,
    required double quantity,
    required String unit,
  }) async {
    try {
      final response = await _dio.post('/shopping-lists/$listId/items', data: {
        'customName': name,
        'quantity': quantity,
        'unit': unit,
      });
      final item = ShoppingListItem.fromJson(response.data as Map<String, dynamic>);
      final list = lists.firstWhere((l) => l.id == listId);
      list.items.add(item);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
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
