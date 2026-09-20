class MissingIngredient {
  final String ingredientId;
  final String name;
  final double quantity;
  final String unit;

  MissingIngredient({
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory MissingIngredient.fromJson(Map<String, dynamic> json) => MissingIngredient(
        ingredientId: json['ingredientId'] as String,
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
      );
}
