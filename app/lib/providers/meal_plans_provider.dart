import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/meal_plan.dart';

class MealPlansProvider extends ChangeNotifier {
  final _dio = ApiClient.instance.dio;

  List<MealPlan> mealPlans = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _dio.get('/meal-plans');
      mealPlans = (response.data as List)
          .map((e) => MealPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      errorMessage = 'No se pudieron cargar los planes.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<MealPlan?> generate(int days) async {
    try {
      final response = await _dio.post('/meal-plans/generate', data: {'days': days});
      final plan = MealPlan.fromJson(response.data as Map<String, dynamic>);
      mealPlans = [plan, ...mealPlans];
      notifyListeners();
      return plan;
    } catch (_) {
      return null;
    }
  }
}
