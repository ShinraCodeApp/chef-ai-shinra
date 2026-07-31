import 'ingredient.dart';

class InventoryItem {
  final String id;
  final String ingredientId;
  final Ingredient ingredient;
  final double quantity;
  final String unit;
  final String state;
  final String? expirationDate;
  final String source;

  InventoryItem({
    required this.id,
    required this.ingredientId,
    required this.ingredient,
    required this.quantity,
    required this.unit,
    required this.state,
    this.expirationDate,
    required this.source,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        ingredientId: json['ingredientId'] as String,
        ingredient: Ingredient.fromJson(json['ingredient'] as Map<String, dynamic>),
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        state: json['state'] as String,
        expirationDate: json['expirationDate'] as String?,
        source: json['source'] as String,
      );
}
