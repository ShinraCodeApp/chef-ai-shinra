import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Envuelve las notificaciones locales (recordatorios de horario de comida, avisos
/// de lista de compras e ingredientes agotados). No hay push real desde el backend:
/// todo se agenda desde la propia app con los datos que ya tiene cargados.
class NotificationsService {
  NotificationsService._internal();

  static final NotificationsService instance = NotificationsService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'chef_ai_reminders';
  static const _channelName = 'Recordatorios';
  static const _channelDescription =
      'Horarios de comida, lista de compras e ingredientes agotados';

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    // La app es de uso personal en Argentina: se fija la zona horaria en vez de
    // agregar un paquete extra solo para detectarla del dispositivo.
    tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (when.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> showNow({required String title, required String body}) {
    return _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }
}
