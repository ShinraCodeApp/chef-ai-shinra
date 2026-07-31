import 'api_client.dart';
import '../models/ingredient.dart';
import '../models/paginated.dart';

/// Helper sin estado para buscar/crear ingredientes del catálogo — usado por
/// pantallas puntuales (agregar al inventario) que no necesitan un provider propio.
class IngredientsApi {
  static Future<List<Ingredient>> search(String query) async {
    final response = await ApiClient.instance.dio.get('/ingredients', queryParameters: {
      if (query.isNotEmpty) 'search': query,
      'limit': 10,
    });
    final paginated = Paginated<Ingredient>.fromJson(
      response.data as Map<String, dynamic>,
      Ingredient.fromJson,
    );
    return paginated.items;
  }

  static Future<Ingredient> create({
    required String name,
    required String category,
    required String unit,
  }) async {
    final response = await ApiClient.instance.dio.post('/ingredients', data: {
      'name': name,
      'category': category,
      'unit': unit,
    });
    return Ingredient.fromJson(response.data as Map<String, dynamic>);
  }
}
