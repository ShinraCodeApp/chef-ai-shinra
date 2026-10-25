import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/meal_type_schedule.dart';
import '../core/notifications_service.dart';
import '../models/meal_plan.dart';
import '../core/i18n.dart';

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
      errorMessage = tr('No se pudieron cargar los planes.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<MealPlan?> generate(int days, {List<String>? mealTypes}) async {
    try {
      final response = await _dio.post('/meal-plans/generate', data: {
        'days': days,
        'startDate': _dateKey(DateTime.now()),
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

  /// Plan vacío (7, 15 o 30 días desde hoy) para armarlo a mano.
  Future<MealPlan?> createManual(int days) async {
    try {
      final response = await _dio.post('/meal-plans',
          data: {'days': days, 'startDate': _dateKey(DateTime.now())});
      final plan = MealPlan.fromJson(response.data as Map<String, dynamic>);
      mealPlans = [plan, ...mealPlans];
      notifyListeners();
      return plan;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deletePlan(String planId) async {
    try {
      await _dio.delete('/meal-plans/$planId');
    } catch (_) {
      return false;
    }
    final removed =
        mealPlans.where((p) => p.id == planId).expand((p) => p.entries).toList();
    mealPlans = mealPlans.where((p) => p.id != planId).toList();
    notifyListeners();
    try {
      for (final entry in removed) {
        await NotificationsService.instance.cancel(_notificationId(entry.id));
      }
    } catch (_) {}
    return true;
  }

  Future<bool> addEntry(
    String planId, {
    required String date,
    required String mealType,
    String? recipeId,
  }) =>
      _saveEntry(planId, null, () => _dio.post('/meal-plans/$planId/entries', data: {
            'date': date,
            'mealType': mealType,
            'recipeId': ?recipeId,
          }));

  /// Cambia la receta, el día o la comida (desayuno, almuerzo…) de una entrada.
  Future<bool> updateEntry(
    String planId,
    String entryId, {
    String? date,
    String? mealType,
    String? recipeId,
  }) =>
      _saveEntry(planId, entryId, () => _dio.patch('/meal-plans/$planId/entries/$entryId', data: {
            'date': ?date,
            'mealType': ?mealType,
            'recipeId': ?recipeId,
          }));

  /// Cambia una comida por otra que propone la IA.
  Future<bool> suggestEntry(String planId, String entryId) => _saveEntry(
      planId, entryId, () => _dio.post('/meal-plans/$planId/entries/$entryId/suggest'));

  Future<bool> removeEntry(String planId, String entryId) async {
    try {
      await _dio.delete('/meal-plans/$planId/entries/$entryId');
      final plan = mealPlans.firstWhere((p) => p.id == planId);
      plan.entries.removeWhere((e) => e.id == entryId);
      notifyListeners();
    } catch (_) {
      return false;
    }
    try {
      await NotificationsService.instance.cancel(_notificationId(entryId));
    } catch (_) {}
    return true;
  }

  /// Guarda una entrada nueva o editada y la reemplaza en el plan en memoria.
  Future<bool> _saveEntry(
    String planId,
    String? entryId,
    Future<dynamic> Function() request,
  ) async {
    final MealPlanEntry entry;
    final MealPlan plan;
    try {
      final response = await request();
      entry = MealPlanEntry.fromJson(response.data as Map<String, dynamic>);
      plan = mealPlans.firstWhere((p) => p.id == planId);
      final index = plan.entries.indexWhere((e) => e.id == (entryId ?? entry.id));
      if (index >= 0) {
        plan.entries[index] = entry;
      } else {
        plan.entries.add(entry);
      }
      notifyListeners();
    } catch (_) {
      return false;
    }
    // el cambio ya quedó guardado: si falla el recordatorio no es un error
    try {
      await NotificationsService.instance.cancel(_notificationId(entry.id));
      await _scheduleRemindersForPlan(
          MealPlan(id: plan.id, startDate: plan.startDate, endDate: plan.endDate, entries: [entry]));
    } catch (_) {}
    return true;
  }

  /// Marca/desmarca una comida. Devuelve `true` si con este toggle el día quedó
  /// recién completo (todas sus comidas marcadas) — se usa para festejar el día.
  Future<bool> toggleEntryCompleted(String planId, String entryId) async {
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
        if (_isDayFullyCompleted(plan, entry.date)) {
          final streak = streakForPlan(plan);
          await NotificationsService.instance.showNow(
            title: tr('¡Día completado! 🎉'),
            body: streak > 1
                ? tr('Cumpliste todas las comidas de hoy. ¡Racha de {streak} días seguidos!', {'streak': streak})
                : tr('Cumpliste todas las comidas de hoy. ¡Seguí así!'),
          );
          return true;
        }
      }
      return false;
    } catch (_) {
      // si falla, la UI simplemente no refleja el cambio; el usuario puede reintentar
      return false;
    }
  }

  bool _isDayFullyCompleted(MealPlan plan, String date) {
    final dayEntries = plan.entries.where((e) => e.date == date).toList();
    return dayEntries.isNotEmpty && dayEntries.every((e) => e.completed);
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Días consecutivos con todas las comidas cumplidas, terminando hoy (si ya está
  /// completo) o ayer (para no penalizar un día que todavía no terminó).
  int streakForPlan(MealPlan plan) {
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if (!_isDayFullyCompleted(plan, _dateKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (_isDayFullyCompleted(plan, _dateKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
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
        title: tr('Es hora de comer'),
        body: entry.recipe.title,
      );
    }
  }

  int _notificationId(String entryId) => entryId.hashCode & 0x7fffffff;
}
