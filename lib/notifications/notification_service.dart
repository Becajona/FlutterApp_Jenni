// lib/notifications/notification_service.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

// Extras para abrir pantallas de ajustes / permisos
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;

  /// Inicializa el plugin y carga la base de zonas horarias.
  /// Usamos tz.local (hora local del dispositivo) sin plugins extra.
  static Future<void> init() async {
    if (kIsWeb || _ready) return;

    // Requerido por zonedSchedule
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    _ready = true;
  }

  /// Android 13+: en tu versión del plugin no hay requestPermission(),
  /// así que la dejamos no-op para compatibilidad.
  static Future<void> requestAndroid13Permission() async {
    return;
  }

  /// Notificación inmediata (debug).
  static Future<void> showTestNow() async {
    if (kIsWeb || !_ready) return;
    await _plugin.show(
      999,
      'Prueba inmediata',
      'Si ves esto, las notificaciones funcionan.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'quincena',
          'Recordatorios quincenales',
          channelDescription: 'Canal de recordatorios/pruebas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Programa una notificación única en N minutos (debug).
  static Future<void> scheduleTestInMinutes(int minutes) async {
    if (kIsWeb || !_ready) return;

    final when = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));

    await _plugin.zonedSchedule(
      2000 + minutes,
      'Prueba programada',
      'Debería aparecer en ~$minutes minuto(s).',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'quincena',
          'Recordatorios quincenales',
          channelDescription: 'Canal de recordatorios/pruebas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // FLN >= 17:
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Si tu versión no soporta la línea anterior, cámbiala por:
      // androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Recordatorios el 1 y 16 de cada mes a la hora/minuto dados.
  static Future<void> scheduleQuincenal({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb || !_ready) return;

    // Reprograma limpio
    await _plugin.cancel(1001);
    await _plugin.cancel(1002);

    Future<void> schedule(int id, int dayOfMonth) async {
      final now = tz.TZDateTime.now(tz.local);
      var next =
          tz.TZDateTime(tz.local, now.year, now.month, dayOfMonth, hour, minute);

      if (next.isBefore(now)) {
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        next =
            tz.TZDateTime(tz.local, nextYear, nextMonth, dayOfMonth, hour, minute);
      }

      await _plugin.zonedSchedule(
        id,
        'Recordatorio quincenal',
        'Registra tus gastos y cierra la quincena.',
        next,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'quincena',
            'Recordatorios quincenales',
            channelDescription: 'Avisos para registrar gastos el 1 y 16.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Si no compila, usa:
        // androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    }

    await schedule(1001, 1);
    await schedule(1002, 16);
  }

  static Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  static Future<void> cancelAll() async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancelAll();
  }
}

/// ===== Helpers de permisos / ajustes (Android & iOS) =====
extension NotificationPermissionHelpers on NotificationService {
  /// Pide permisos de notificación al usuario.
  /// - iOS: solicita alert/badge/sound.
  /// - Android: algunas ROMs requieren que el usuario lo habilite manualmente (abrimos ajustes).
  static Future<void> requestUserPermissions() async {
    // iOS: pedir permisos directamente
    final iosImpl = NotificationService._plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    // Android: en tu versión del plugin no hay `requestPermission()`.
    // Recomendación: abre los ajustes de notificaciones para que el usuario lo active.
    if (Platform.isAndroid) {
      await openAppNotificationSettings();
    }
  }

  /// Abre los **ajustes de notificaciones de la app**.
  static Future<void> openAppNotificationSettings() async {
    if (Platform.isAndroid) {
      final info = await PackageInfo.fromPlatform();
      final intent = AndroidIntent(
        action: 'android.settings.APP_NOTIFICATION_SETTINGS',
        arguments: {
          'android.provider.extra.APP_PACKAGE': info.packageName,
        },
      );
      await intent.launch();
    } else if (Platform.isIOS) {
      // iOS: abre la pantalla de ajustes de la app
      await launchUrl(Uri.parse('app-settings:'));
    }
  }

  /// Abre la pantalla para permitir **alarmas exactas** (Android 12+).
  static Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    final info = await PackageInfo.fromPlatform();
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      data: 'package:${info.packageName}',
    );
    await intent.launch();
  }

  /// Abre la pantalla para **excluir de optimizaciones de batería** (Android).
  static Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;
    const intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    );
    await intent.launch();
  }
}
