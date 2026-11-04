import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'core/analytics.dart';
import 'core/push.dart';
import 'data/fake/fake_repository.dart';
import 'data/app_repository.dart';
import 'data/report_queue.dart';
import 'data/supabase/supabase_repository.dart';
import 'l10n/language_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppRepository repository;
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabasePublishableKey);
    repository = SupabaseRepository(Supabase.instance.client);
  } else {
    repository = FakeRepository();
  }

  final push = AppConfig.hasOneSignal ? OneSignalPushService(AppConfig.oneSignalAppId) : null;

  final dir = (await getApplicationSupportDirectory()).path;
  // Antrean laporan offline hanya disimpan ke file untuk data sungguhan (mode demo di memori)
  final reportStore = AppConfig.hasSupabase ? FileReportQueueStore(File('$dir/report_queue.json')) : null;
  final languageStore = FileLanguageStore(File('$dir/language.txt'));

  final analytics = AppConfig.hasPostHog
      ? PostHogAnalytics(apiKey: AppConfig.postHogApiKey, host: AppConfig.postHogHost)
      : null;

  runApp(
    FamilyPointsApp(
      repository: repository,
      push: push,
      analytics: analytics,
      reportStore: reportStore,
      languageStore: languageStore,
    ),
  );
}
