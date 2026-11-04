import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/analytics.dart';
import 'core/photo_picker.dart';
import 'core/push.dart';
import 'core/theme/app_theme.dart';
import 'data/app_repository.dart';
import 'data/report_queue.dart';
import 'features/shell/session.dart';
import 'l10n/language_store.dart';
import 'l10n/strings.dart';
import 'router.dart';

class FamilyPointsApp extends StatefulWidget {
  const FamilyPointsApp({
    super.key,
    required this.repository,
    this.photoPicker,
    this.push,
    this.analytics,
    this.reportStore,
    this.languageStore,
  });

  final AppRepository repository;

  /// Sumber foto bukti; default kamera HP. Tes memakai versi palsu.
  final PhotoPicker? photoPicker;

  /// Push notification; default tanpa push (mode demo & tes).
  final PushService? push;

  /// Analitik; default tidak mengirim apa-apa.
  final Analytics? analytics;

  /// Penyimpanan antrean laporan offline; default di memori.
  final ReportQueueStore? reportStore;

  /// Bahasa terakhir di HP ini; default di memori.
  final LanguageStore? languageStore;

  @override
  State<FamilyPointsApp> createState() => _FamilyPointsAppState();
}

class _FamilyPointsAppState extends State<FamilyPointsApp> {
  late final SessionController _session = SessionController(
    widget.repository,
    push: widget.push ?? const NoopPushService(),
    analytics: widget.analytics ?? const NoopAnalytics(),
    reportStore: widget.reportStore,
    languageStore: widget.languageStore,
  )..start();
  late final GoRouter _router = buildRouter(_session);
  late final PhotoPicker _photoPicker = widget.photoPicker ?? DevicePhotoPicker();
  StreamSubscription<String>? _pushRoutes;

  @override
  void initState() {
    super.initState();
    // Notifikasi diketuk: buka layarnya (redirect router tetap menjaga mode orang tua/anak)
    _pushRoutes = _session.push.openedRoutes.listen(_router.go);
  }

  @override
  void dispose() {
    _pushRoutes?.cancel();
    _router.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: _session,
      child: PhotoPickerScope(
        picker: _photoPicker,
        child: ListenableBuilder(
          listenable: _session,
          builder: (context, _) => MaterialApp.router(
            title: 'Family Points',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            routerConfig: _router,
            locale: Locale(_session.language),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: const [S.delegate, ...GlobalMaterialLocalizations.delegates],
          ),
        ),
      ),
    );
  }
}
