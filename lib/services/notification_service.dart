import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/product.dart';
import '../models/app_settings.dart';

/// Garanti bitişi yaklaşan ürünler için cihaz üzerinde (sunucusuz)
/// zamanlanmış bildirimler üretir. Her ürün için sabit, öngörülebilir
/// bildirim kimlikleri kullanılır ki ayarlar değiştiğinde eskiler
/// güvenle iptal edilip yeniden kurulabilsin.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _dailySummaryId = 999999;
  static const _updateAvailableId = 999998;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'vaultify_warranty_channel',
      'Garanti Bildirimleri',
      description: 'Garanti süresi yaklaşan ürünler için hatırlatmalar',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    const updateChannel = AndroidNotificationChannel(
      'vaultify_updates_channel',
      'Uygulama Güncellemeleri',
      description: 'Yeni Vaultify sürümleri için bildirimler',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(updateChannel);

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  Future<void> showUpdateAvailable({
    required String version,
    required String downloadUrl,
  }) async {
    await requestPermissions();
    const androidDetails = AndroidNotificationDetails(
      'vaultify_updates_channel',
      'Uygulama Güncellemeleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      _updateAvailableId,
      'Yeni Vaultify güncellemesi hazır',
      'Sürüm $version indirilmeye hazır. GitHub yayın sayfasından güncelleyebilirsiniz.',
      details,
      payload: downloadUrl,
    );
  }

  int _oneMonthId(String productId) => productId.hashCode & 0x7fffffff;
  int _lastWeekId(String productId) =>
      (productId.hashCode ^ 0x5f5f5f5f) & 0x7fffffff;

  Future<void> cancelForProduct(String productId) async {
    await _plugin.cancel(_oneMonthId(productId));
    await _plugin.cancel(_lastWeekId(productId));
  }

  /// Ürünün garanti tarihlerine göre bildirimleri (yeniden) planlar.
  Future<void> scheduleForProduct(
    WarrantyProduct product,
    AppSettings settings,
  ) async {
    await cancelForProduct(product.id);
    if (product.isExpired) return;

    const androidDetails = AndroidNotificationDetails(
      'vaultify_warranty_channel',
      'Garanti Bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
        android: androidDetails, iOS: DarwinNotificationDetails());

    if (settings.notifyOneMonthBefore) {
      final fireDate = product.endDate.subtract(const Duration(days: 30));
      await _scheduleAt(
        id: _oneMonthId(product.id),
        title: 'Garanti 1 Ay Sonra Bitiyor',
        body: '${product.name} için garanti süreniz 1 ay içinde sona eriyor.',
        date: fireDate,
        details: details,
      );
    }

    if (settings.notifyLastWeek) {
      final fireDate = product.endDate.subtract(const Duration(days: 7));
      await _scheduleAt(
        id: _lastWeekId(product.id),
        title: 'Son Hafta!',
        body: '${product.name} için garanti süreniz son haftasında.',
        date: fireDate,
        details: details,
      );
    }
  }

  Future<void> rescheduleAll(
    List<WarrantyProduct> products,
    AppSettings settings,
  ) async {
    for (final p in products) {
      await scheduleForProduct(p, settings);
    }
    await setDailySummary(settings.notifyDailySummary);
  }

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    required NotificationDetails details,
  }) async {
    final now = DateTime.now();
    if (date.isBefore(now)) return; // Geçmiş tarihe bildirim kurulmaz.
    final scheduled = tz.TZDateTime.from(date, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Her sabah 09:00 için tekrar eden genel bir hatırlatma kurar.
  /// Not: Yerel bildirimler statiktir; bildirim içeriği o an uygulama
  /// açıldığında güncellenen verilere göre değil, sabit bir metne göre
  /// gösterilir.
  Future<void> setDailySummary(bool enabled) async {
    await _plugin.cancel(_dailySummaryId);
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'vaultify_warranty_channel',
      'Garanti Bildirimleri',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
        android: androidDetails, iOS: DarwinNotificationDetails());

    await _plugin.zonedSchedule(
      _dailySummaryId,
      'Günlük Garanti Özeti',
      'Yaklaşan garanti tarihlerinizi kontrol etmeyi unutmayın.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
