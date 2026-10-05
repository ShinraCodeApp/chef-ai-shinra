import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/expiry.dart';
import '../models/inventory_item.dart';
import '../core/i18n.dart';

class InventoryProvider extends ChangeNotifier {
  final _dio = ApiClient.instance.dio;

  List<InventoryItem> items = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _dio.get('/inventory');
      items = (response.data as List)
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      ExpiryReminders.instance.sync(items);
    } catch (_) {
      errorMessage = tr('No se pudo cargar el inventario.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem({
    required String ingredientId,
    required double quantity,
    required String unit,
    String state = 'fresh',
    String? expirationDate,
    String? source,
  }) async {
    try {
      await _dio.post('/inventory', data: {
        'ingredientId': ingredientId,
        'quantity': quantity,
        'unit': unit,
        'state': state,
        'expirationDate': ?expirationDate,
        'source': ?source,
      });
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeItem(String id) async {
    try {
      await _dio.delete('/inventory/$id');
      items.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
