class AdminStats {
  final int totalUsers;
  final int totalRecipes;
  final int aiGeneratedRecipes;
  final int totalIngredients;
  final int totalInventoryItems;

  AdminStats({
    required this.totalUsers,
    required this.totalRecipes,
    required this.aiGeneratedRecipes,
    required this.totalIngredients,
    required this.totalInventoryItems,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: json['totalUsers'] as int,
        totalRecipes: json['totalRecipes'] as int,
        aiGeneratedRecipes: json['aiGeneratedRecipes'] as int,
        totalIngredients: json['totalIngredients'] as int,
        totalInventoryItems: json['totalInventoryItems'] as int,
      );
}
