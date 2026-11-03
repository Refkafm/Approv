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

  // Antrean laporan offline hanya disimpan ke file untuk data sungguhan (mode demo di memori)
  final reportStore = AppConfig.hasSupabase
      ? FileReportQueueStore(File('${(await getApplicationSupportDirectory()).path}/report_queue.json'))
      : null;

  final analytics = AppConfig.hasPostHog
      ? PostHogAnalytics(apiKey: AppConfig.postHogApiKey, host: AppConfig.postHogHost)
      : null;

  runApp(FamilyPointsApp(repository: repository, push: push, analytics: analytics, reportStore: reportStore));
}
