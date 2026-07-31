class Ingredient {
  final String id;
  final String name;
  final String category;
  final String unit;
  final String? barcode;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? carbsPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? sodiumPer100g;
  final String? imageUrl;

  Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    this.barcode,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.carbsPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumPer100g,
    this.imageUrl,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        unit: json['unit'] as String,
        barcode: json['barcode'] as String?,
        caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble(),
        proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble(),
        fatPer100g: (json['fatPer100g'] as num?)?.toDouble(),
        carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble(),
        fiberPer100g: (json['fiberPer100g'] as num?)?.toDouble(),
        sugarPer100g: (json['sugarPer100g'] as num?)?.toDouble(),
        sodiumPer100g: (json['sodiumPer100g'] as num?)?.toDouble(),
        imageUrl: json['imageUrl'] as String?,
      );
}
