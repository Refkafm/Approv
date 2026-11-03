import 'dart:async';

import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Push notification (PRD bagian "Notifikasi"). Server mengirim lewat OneSignal dengan
/// external_id = auth user id, jadi app cukup mengaitkan HP ini ke user yang sedang masuk.
abstract interface class PushService {
  /// Kaitkan HP ini dengan user (dipanggil setelah masuk & punya keluarga).
  Future<void> identify(String userId);

  /// Lepaskan kaitan saat keluar, supaya HP tidak menerima push milik akun sebelumnya.
  Future<void> clear();

  /// Rute app (mis. /parent/approvals) dari notifikasi yang diketuk.
  Stream<String> get openedRoutes;
}

/// Mode demo & tes: tidak mengirim apa-apa.
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> clear() async {}

  @override
  Stream<String> get openedRoutes => const Stream.empty();
}

class OneSignalPushService implements PushService {
  OneSignalPushService(String appId) {
    OneSignal.initialize(appId);
    OneSignal.Notifications.addClickListener((event) {
      final route = event.notification.additionalData?['route'];
      if (route is String && route.startsWith('/')) _routes.add(route);
    });
  }

  // Bukan broadcast: ketukan saat app baru dibuka ditahan sampai app.dart mendengarkan
  final _routes = StreamController<String>();
  bool _askedPermission = false;

  @override
  Future<void> identify(String userId) async {
    await OneSignal.login(userId);
    if (_askedPermission) return;
    _askedPermission = true;
    // Ditanyakan setelah keluarga siap, bukan saat app pertama dibuka
    if (!OneSignal.Notifications.permission) await OneSignal.Notifications.requestPermission(true);
  }

  @override
  Future<void> clear() => OneSignal.logout();

  @override
  Stream<String> get openedRoutes => _routes.stream;
}
