import 'ingredient.dart';

class ShoppingListItem {
  final String id;
  final Ingredient? ingredient;
  final String? customName;
  final double quantity;
  final String unit;
  final String category;
  bool isChecked;

  ShoppingListItem({
    required this.id,
    this.ingredient,
    this.customName,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.isChecked,
  });

  String get displayName => ingredient?.name ?? customName ?? 'Ítem';

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) => ShoppingListItem(
        id: json['id'] as String,
        ingredient: json['ingredient'] != null
            ? Ingredient.fromJson(json['ingredient'] as Map<String, dynamic>)
            : null,
        customName: json['customName'] as String?,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        category: json['category'] as String,
        isChecked: json['isChecked'] as bool? ?? false,
      );
}

class ShoppingList {
  final String id;
  final String name;
  final List<ShoppingListItem> items;

  ShoppingList({required this.id, required this.name, required this.items});

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
        id: json['id'] as String,
        name: json['name'] as String,
        items: (json['items'] as List? ?? [])
            .map((e) => ShoppingListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
