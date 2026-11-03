import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Event metrik sukses fase 1 (Rencana-Implementasi, "Instrumentasi metrik sukses").
abstract final class AnalyticsEvent {
  static const familyCreated = 'family_created';
  static const childJoined = 'child_joined';

  /// 3 tugas + 2 hadiah + 1 anak
  static const setupCompleted = 'setup_completed';
  static const taskSubmitted = 'task_submitted';

  /// Dengan durasi lapor → tinjau (menit)
  static const submissionReviewed = 'submission_reviewed';

  /// Jenis instan/goal
  static const rewardRedeemed = 'reward_redeemed';
  static const goalAchieved = 'goal_achieved';
}

/// Data anak minimal: hanya auth user id (acak) dan properti angka/jenis, tanpa nama atau isi laporan.
abstract interface class Analytics {
  /// null = keluar; event berikutnya tidak dikirim sampai ada user lagi.
  void identify(String? userId);

  void track(String event, [Map<String, Object> properties = const {}]);
}

/// Mode demo & tes.
class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  void identify(String? userId) {}

  @override
  void track(String event, [Map<String, Object> properties = const {}]) {}
}

/// PostHog lewat HTTP capture API (tanpa SDK native, tanpa autocapture).
class PostHogAnalytics implements Analytics {
  PostHogAnalytics({required this.apiKey, required this.host, http.Client? client}) : _client = client ?? http.Client();

  final String apiKey;
  final String host;
  final http.Client _client;
  String? _userId;

  @override
  void identify(String? userId) => _userId = userId;

  @override
  void track(String event, [Map<String, Object> properties = const {}]) {
    final userId = _userId;
    if (userId == null) return;
    unawaited(_send(event, userId, properties));
  }

  Future<void> _send(String event, String userId, Map<String, Object> properties) async {
    try {
      await _client.post(
        Uri.parse('$host/capture/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': apiKey,
          'event': event,
          'distinct_id': userId,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'properties': {...properties, r'$process_person_profile': false},
        }),
      );
    } catch (e) {
      // Analitik tidak boleh mengganggu app; event yang gagal (mis. tanpa sinyal) dilewati
      debugPrint('analytics: $e');
    }
  }
}
