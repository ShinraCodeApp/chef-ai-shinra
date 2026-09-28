import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/meal_type_schedule.dart';
import '../core/notifications_service.dart';
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
      for (final plan in mealPlans) {
        await _scheduleRemindersForPlan(plan);
      }
    } catch (_) {
      errorMessage = 'No se pudieron cargar los planes.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<MealPlan?> generate(int days, {List<String>? mealTypes}) async {
    try {
      final response = await _dio.post('/meal-plans/generate', data: {
        'days': days,
        if (mealTypes != null && mealTypes.isNotEmpty) 'mealTypes': mealTypes,
      });
      final plan = MealPlan.fromJson(response.data as Map<String, dynamic>);
      mealPlans = [plan, ...mealPlans];
      notifyListeners();
      await _scheduleRemindersForPlan(plan);
      return plan;
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleEntryCompleted(String planId, String entryId) async {
    try {
      final response = await _dio
          .patch('/meal-plans/$planId/entries/$entryId/toggle');
      final completed = response.data['completed'] as bool? ?? false;
      final plan = mealPlans.firstWhere((p) => p.id == planId);
      final entry = plan.entries.firstWhere((e) => e.id == entryId);
      entry.completed = completed;
      notifyListeners();
      if (completed) {
        await NotificationsService.instance.cancel(_notificationId(entryId));
      }
    } catch (_) {
      // si falla, la UI simplemente no refleja el cambio; el usuario puede reintentar
    }
  }

  Future<void> _scheduleRemindersForPlan(MealPlan plan) async {
    for (final entry in plan.entries) {
      if (entry.completed) continue;
      final time = kMealTypeDefaultTimes[entry.mealType];
      if (time == null) continue;
      final date = DateTime.tryParse(entry.date);
      if (date == null) continue;
      final when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      await NotificationsService.instance.scheduleAt(
        id: _notificationId(entry.id),
        when: when,
        title: 'Es hora de comer',
        body: entry.recipe.title,
      );
    }
  }

  int _notificationId(String entryId) => entryId.hashCode & 0x7fffffff;
}
