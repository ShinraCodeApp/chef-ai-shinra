import 'ingredient.dart';

class RecipeStep {
  final int order;
  final String instruction;

  RecipeStep({required this.order, required this.instruction});

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        order: json['order'] as int,
        instruction: json['instruction'] as String,
      );
}

class RecipeNutrition {
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;

  RecipeNutrition({
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
  });

  factory RecipeNutrition.fromJson(Map<String, dynamic> json) => RecipeNutrition(
        calories: (json['calories'] as num).toDouble(),
        proteinG: (json['proteinG'] as num).toDouble(),
        fatG: (json['fatG'] as num).toDouble(),
        carbsG: (json['carbsG'] as num).toDouble(),
        fiberG: (json['fiberG'] as num).toDouble(),
        sugarG: (json['sugarG'] as num).toDouble(),
        sodiumMg: (json['sodiumMg'] as num).toDouble(),
      );
}

class RecipeIngredientEntry {
  final String id;
  final Ingredient ingredient;
  final double quantity;
  final String unit;
  final String? notes;

  RecipeIngredientEntry({
    required this.id,
    required this.ingredient,
    required this.quantity,
    required this.unit,
    this.notes,
  });

  factory RecipeIngredientEntry.fromJson(Map<String, dynamic> json) =>
      RecipeIngredientEntry(
        id: json['id'] as String,
        ingredient: Ingredient.fromJson(json['ingredient'] as Map<String, dynamic>),
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        notes: json['notes'] as String?,
      );
}

class Recipe {
  final String id;
  final String title;
  final String description;
  final List<RecipeStep> instructions;
  final int servings;
  final int prepTimeMinutes;
  final String difficulty;
  final double? estimatedCostTotal;
  final String? imageUrl;
  final List<String> dietTags;
  final bool isAiGenerated;
  final RecipeNutrition? nutrition;
  final List<RecipeIngredientEntry> recipeIngredients;
  final List<String> tips;
  bool isFavorite;
  final bool? isMainIngredientMatch;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.servings,
    required this.prepTimeMinutes,
    required this.difficulty,
    this.estimatedCostTotal,
    this.imageUrl,
    required this.dietTags,
    required this.isAiGenerated,
    this.nutrition,
    required this.recipeIngredients,
    this.tips = const [],
    this.isFavorite = false,
    this.isMainIngredientMatch,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        instructions: (json['instructions'] as List? ?? [])
            .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        servings: json['servings'] as int,
        prepTimeMinutes: json['prepTimeMinutes'] as int,
        difficulty: json['difficulty'] as String,
        estimatedCostTotal: (json['estimatedCostTotal'] as num?)?.toDouble(),
        imageUrl: json['imageUrl'] as String?,
        dietTags:
            (json['dietTags'] as List? ?? []).map((e) => e.toString()).toList(),
        isAiGenerated: json['isAiGenerated'] as bool? ?? false,
        nutrition: json['nutrition'] != null
            ? RecipeNutrition.fromJson(json['nutrition'] as Map<String, dynamic>)
            : null,
        recipeIngredients: (json['recipeIngredients'] as List? ?? [])
            .map((e) => RecipeIngredientEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        tips: (json['tips'] as List? ?? []).map((e) => e.toString()).toList(),
        isFavorite: json['isFavorite'] as bool? ?? false,
        isMainIngredientMatch: json['isMainIngredientMatch'] as bool?,
      );
}
