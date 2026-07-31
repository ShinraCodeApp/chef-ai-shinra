import 'recipe.dart';

class MealPlanEntry {
  final String id;
  final String date;
  final String mealType;
  final Recipe recipe;

  MealPlanEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.recipe,
  });

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        id: json['id'] as String,
        date: json['date'] as String,
        mealType: json['mealType'] as String,
        recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
      );
}

class MealPlan {
  final String id;
  final String startDate;
  final String endDate;
  final List<MealPlanEntry> entries;

  MealPlan({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.entries,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
        id: json['id'] as String,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
        entries: (json['entries'] as List? ?? [])
            .map((e) => MealPlanEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
