import 'dart:async';
import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../config.dart';
import '../../core/indonesia.dart';
import '../app_exception.dart';
import '../app_repository.dart';
import '../family_repository.dart';
import '../models.dart';
import '../photo_models.dart';
import '../reward_models.dart';
import '../reward_repository.dart';
import '../settings_models.dart';
import '../submission_repository.dart';
import '../task_models.dart';
import '../task_repository.dart';
import '../task_rules.dart';
import '../wallet_models.dart';
import '../wallet_repository.dart';
import '../wallet_rules.dart';

part 'supabase_family.dart';
part 'supabase_rewards.dart';
part 'supabase_settings.dart';
part 'supabase_submissions.dart';
part 'supabase_tasks.dart';
part 'supabase_wallet.dart';

/// Implementasi produksi: RPC & tabel dari supabase/migrations. Hak akses dijaga RLS di server.
class SupabaseRepository extends _SupabaseBase
    with _SupabaseFamily, _SupabaseTasks, _SupabaseSubmissions, _SupabaseWallet, _SupabaseRewards, _SupabaseSettings
    implements AppRepository {
  SupabaseRepository(super.client);
}

abstract class _SupabaseBase {
  _SupabaseBase(this._client);

  final SupabaseClient _client;

  /// Satu channel realtime per keluarga, dipakai bersama semua layar (lihat watchFamily).
  final _familyChanges = <String, StreamController<void>>{};

  /// Ubah error Supabase menjadi [AppException]. Pesan exception RPC = kode mesin.
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      throw AppException(e.message, detail: e.details?.toString());
    } on AuthException {
      throw const AppException('auth_failed');
    } on http.ClientException {
      // Sinyal putus / server tak terjangkau (IOClient membungkus SocketException)
      throw const AppException('offline');
    } on TimeoutException {
      throw const AppException('offline');
    }
  }
}

String _isoDate(DateTime date) => date.toIso8601String().substring(0, 10);
