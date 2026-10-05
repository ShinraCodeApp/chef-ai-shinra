import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_item.dart';
import 'notifications_service.dart';

/// Días hasta que vence (0 = hoy, negativo = ya venció). null si no tiene fecha.
int? daysUntilExpiry(InventoryItem item, DateTime now) {
  final raw = item.expirationDate;
  if (raw == null) return null;
  final date = DateTime.tryParse(raw);
  if (date == null) return null;
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  return day.difference(today).inDays;
}

/// Lo que vence hoy o en los próximos [days] días (sin los ya vencidos),
/// ordenado por fecha.
List<InventoryItem> expiringSoon(
  List<InventoryItem> items,
  DateTime now, {
  int days = 3,
}) {
  final soon = items.where((i) {
    final d = daysUntilExpiry(i, now);
    return d != null && d >= 0 && d <= days;
  }).toList()
    ..sort((a, b) => daysUntilExpiry(a, now)!.compareTo(daysUntilExpiry(b, now)!));
  return soon;
}

String expiryLabel(int days) => switch (days) {
      0 => 'vence hoy',
      1 => 'vence mañana',
      _ => 'vence en $days días',
    };

/// Una notificación programada: a las 10 hs del día anterior y del mismo día
/// en que vence cada producto.
class ExpiryReminder {
  final int id;
  final DateTime when;
  final String title;
  final String body;
  const ExpiryReminder(this.id, this.when, this.title, this.body);
}

const _firstId = 7000; // rango reservado para vencimientos: 7000–7099
const _maxReminders = 100;

List<ExpiryReminder> planExpiryReminders(List<InventoryItem> items, DateTime now) {
  final reminders = <ExpiryReminder>[];
  final upcoming = items.where((i) => (daysUntilExpiry(i, now) ?? -1) >= 0).toList()
    ..sort((a, b) => daysUntilExpiry(a, now)!.compareTo(daysUntilExpiry(b, now)!));
  for (final item in upcoming) {
    final days = daysUntilExpiry(item, now)!;
    final expiry = DateTime(now.year, now.month, now.day).add(Duration(days: days));
    final name = item.ingredient.name;
    for (final (offset, label) in [(1, 'vence mañana'), (0, 'vence hoy')]) {
      final when = expiry.subtract(Duration(days: offset)).add(const Duration(hours: 10));
      if (!when.isAfter(now) || reminders.length >= _maxReminders) continue;
      reminders.add(ExpiryReminder(
        _firstId + reminders.length,
        when,
        '${name[0].toUpperCase()}${name.substring(1)}: $label',
        'Abrí Chef AI y cociná algo con lo que está por vencer.',
      ));
    }
  }
  return reminders;
}

/// Reprograma los avisos cada vez que se carga el inventario.
class ExpiryReminders {
  ExpiryReminders._();
  static final instance = ExpiryReminders._();
  static const _countKey = 'expiry_reminders_count';

  Future<void> sync(List<InventoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final previous = prefs.getInt(_countKey) ?? 0;
      for (var i = 0; i < previous; i++) {
        await NotificationsService.instance.cancel(_firstId + i);
      }
      final plan = planExpiryReminders(items, DateTime.now());
      for (final r in plan) {
        await NotificationsService.instance.scheduleAt(
          id: r.id,
          when: r.when,
          title: r.title,
          body: r.body,
        );
      }
      await prefs.setInt(_countKey, plan.length);
    } catch (_) {
      // sin permiso de notificaciones o en tests: el inventario sigue andando
    }
  }
}
