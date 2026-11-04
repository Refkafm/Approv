import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/analytics.dart';
import '../../core/push.dart';
import '../../data/app_exception.dart';
import '../../data/fake/fake_repository.dart';
import '../../data/app_repository.dart';
import '../../data/models.dart';
import '../../data/report_queue.dart';
import '../../l10n/language_store.dart';

enum AppMode { parent, child }

/// Status login & keanggotaan. Mode tampilan ditentukan peran akun yang login
/// (PRD "Daftar layar"); router memakai ini untuk redirect.
class SessionController extends ChangeNotifier {
  SessionController(
    this.repository, {
    this.push = const NoopPushService(),
    this.analytics = const NoopAnalytics(),
    ReportQueueStore? reportStore,
    LanguageStore? languageStore,
  }) : reports = ReportQueue(repository, store: reportStore),
       _languageStore = languageStore ?? MemoryLanguageStore();

  final AppRepository repository;
  final PushService push;
  final Analytics analytics;

  /// Laporan yang menunggu sinyal; dikirim ulang saat app dibuka, kembali ke depan, dan tiap 30 detik.
  final ReportQueue reports;
  AppLifecycleListener? _lifecycle;
  Timer? _retryTimer;
  bool _disposed = false;
  String? _pushUserId;
  StreamSubscription<void>? _authSub;

  final LanguageStore _languageStore;
  String _language = 'id';

  /// Bahasa app ('id' / 'en'): pengaturan keluarga (PRD), atau pilihan di layar awal sebelum login.
  String get language => _language;

  /// Ganti bahasa di HP ini. Untuk keluarga, pengaturan keluarga tetap sumber utamanya.
  Future<void> setLanguage(String code) async {
    if (code != 'id' && code != 'en') return;
    if (code != _language) {
      _language = code;
      notifyListeners();
    }
    await _languageStore.save(code);
  }

  AuthUser? _user;
  List<Member> _memberships = const [];
  bool _ready = false;
  bool _inFlow = false;

  AuthUser? get user => _user;
  bool get ready => _ready;

  /// Mode demo: data hanya di memori (tanpa Supabase).
  bool get isDemo => repository is FakeRepository;

  /// Sedang di tengah alur bertahap (onboarding / gabung keluarga): router tidak memindahkan layar.
  bool get inFlow => _inFlow;

  /// Profil aktif. Pilih profil + PIN di HP bersama (A-05) menyusul; sementara anggota pertama.
  Member? get activeMember => _memberships.isEmpty ? null : _memberships.first;

  AppMode? get mode {
    final member = activeMember;
    if (member == null) return null;
    return member.role.isAdmin ? AppMode.parent : AppMode.child;
  }

  Future<void> start() async {
    _authSub ??= repository.authChanges.listen((_) => refresh());
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(flushReports()));
    _language = await _languageStore.load() ?? _language;
    await reports.load();
    await refresh();
  }

  /// Kirim laporan yang tertunda milik profil aktif; layar dimuat ulang bila ada yang terkirim.
  Future<void> flushReports() async {
    final member = activeMember;
    if (member == null || reports.pendingFor(member.id).isEmpty) {
      _retryTimer?.cancel();
      _retryTimer = null;
      return;
    }
    final sent = await reports.flush(member);
    if (_disposed) return;
    if (sent > 0) markDataChanged();
    if (reports.pendingFor(member.id).isEmpty) {
      _retryTimer?.cancel();
      _retryTimer = null;
    } else {
      _retryTimer ??= Timer.periodic(const Duration(seconds: 30), (_) => unawaited(flushReports()));
    }
  }

  Future<void> refresh() async {
    try {
      final user = await repository.currentUser();
      _memberships = user == null ? const [] : await repository.myMemberships();
      _user = user;
    } on AppException {
      // Biarkan data sebelumnya; layar akan mencoba lagi saat refresh berikutnya
    }
    final member = activeMember;
    if (member != null) {
      try {
        await setLanguage((await repository.familySettings(member.familyId)).locale);
      } on AppException {
        // Tetap pakai bahasa terakhir di HP ini
      }
    }
    _ready = true;
    analytics.identify(_user?.id);
    notifyListeners();
    unawaited(_syncPush());
    unawaited(flushReports());
  }

  /// HP dikaitkan ke user hanya setelah punya keluarga; dilepas saat keluar.
  Future<void> _syncPush() async {
    final target = _memberships.isEmpty ? null : _user?.id;
    if (target == _pushUserId) return;
    _pushUserId = target;
    try {
      if (target == null) {
        await push.clear();
      } else {
        await push.identify(target);
      }
    } catch (e) {
      // Push opsional: kegagalan (mis. izin ditolak, tanpa jaringan) tidak boleh mengganggu app
      debugPrint('push: $e');
    }
  }

  void beginFlow() => _inFlow = true;

  Future<void> finishFlow() async {
    _inFlow = false;
    await refresh();
  }

  Future<void> signOut() async {
    _inFlow = false;
    await repository.signOut();
    await refresh();
  }

  /// Naik setiap kali data keluarga diubah dari layar mana pun (mis. form tugas);
  /// layar daftar mendengarkan ini untuk memuat ulang.
  final dataRevision = ValueNotifier<int>(0);

  void markDataChanged() => dataRevision.value++;

  /// Event analitik (lihat AnalyticsEvent); peran ditambahkan otomatis.
  void track(String event, [Map<String, Object> properties = const {}]) {
    final role = activeMember?.role;
    analytics.track(event, {...properties, 'role': ?role?.name});
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    _lifecycle?.dispose();
    _retryTimer?.cancel();
    reports.dispose();
    dataRevision.dispose();
    super.dispose();
  }
}

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({super.key, required SessionController controller, required super.child})
    : super(notifier: controller);

  static SessionController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;

  /// Tanpa berlangganan perubahan (untuk dipakai di callback).
  static SessionController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}
