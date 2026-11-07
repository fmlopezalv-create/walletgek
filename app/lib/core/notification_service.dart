import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/debts/debt_model.dart';
import 'app_state.dart';

/// Programa notificaciones locales para avisar de pagos de deudas próximos.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Cancela y reprograma las notificaciones de todas las deudas activas.
  Future<void> scheduleForDebts(List<Debt> debts) async {
    if (!_initialized) await init();
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    for (final d in debts) {
      if (d.balance <= 0 || d.minimumPayment <= 0) continue;
      final dueDay = _dueDay(d);
      if (dueDay == null) continue;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_reminders',
          'Recordatorios de deudas',
          channelDescription: 'Avisos de pagos de deudas próximos o vencidos',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      // Aviso "pago en 3 días"
      await _plugin.zonedSchedule(
        id: d.hashCode * 10 + 1,
        title: 'Pago próximo: ${d.name}',
        body:
            'Vence en 3 días (${AppState.instance.formatAmount(d.minimumPayment)})',
        scheduledDate: _nextOccurrence(dueDay - 3, now),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );

      // Aviso "pago vencido"
      await _plugin.zonedSchedule(
        id: d.hashCode * 10 + 2,
        title: 'Pago vencido: ${d.name}',
        body:
            'Se venció el pago (${AppState.instance.formatAmount(d.minimumPayment)})',
        scheduledDate: _nextOccurrence(dueDay, now),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    }
  }

  /// Devuelve el día del mes (1-31) de la deuda, a partir de dueDate.
  int? _dueDay(Debt d) {
    final due = d.dueDate;
    if (due != null) return due.day;
    return null;
  }

  /// Próxima fecha del mes que cae en [day] (clamp a 28) a las 09:00.
  tz.TZDateTime _nextOccurrence(int day, tz.TZDateTime now) {
    final d = day.clamp(1, 28);
    var date = tz.TZDateTime(tz.local, now.year, now.month, d, 9);
    if (!date.isAfter(now)) {
      date = tz.TZDateTime(tz.local, now.year, now.month + 1, d, 9);
    }
    return date;
  }
}
