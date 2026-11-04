import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../../core/indonesia.dart';
import '../app_exception.dart';
import '../app_repository.dart';
import '../economy_template.dart';
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

part 'fake_family.dart';
part 'fake_rewards.dart';
part 'fake_settings.dart';
part 'fake_submissions.dart';
part 'fake_tasks.dart';
part 'fake_wallet.dart';

/// Repository di memori untuk tes dan mode demo (tanpa Supabase).
/// Meniru aturan RPC & RLS yang relevan; tes di test/fake_*_test.dart menjaga keduanya tetap sama.
class FakeRepository extends _FakeState
    with _FakeFamily, _FakeTasks, _FakeSubmissions, _FakeWallet, _FakeRewards, _FakeSettings
    implements AppRepository {
  FakeRepository({super.clock, super.random});

  /// Kode OTP yang selalu diterima di mode demo.
  static const demoOtp = '123456';
}

/// State bersama semua domain fake.
abstract class _FakeState {
  _FakeState({DateTime Function()? clock, Random? random})
    : _clock = clock ?? DateTime.now,
      _random = random ?? Random();

  final DateTime Function() _clock;
  final Random _random;
  final _auth = StreamController<void>.broadcast();
  final _recovery = StreamController<void>.broadcast();

  /// family id yang datanya berubah (meniru realtime Supabase)
  final _changes = StreamController<String>.broadcast();
  int _seq = 0;

  AuthUser? _user;
  final _emailAccounts = <String, String>{};

  /// Email akun yang masuk lewat tautan atur ulang kata sandi.
  String? _recoveryEmail;

  /// Untuk tes: kirim laporan gagal seperti saat HP tanpa sinyal.
  bool debugOffline = false;

  /// family id -> timezone
  final _families = <String, String>{};
  final _settings = <String, FamilySettings>{};
  final _members = <String, _FakeMember>{};
  final _invites = <String, _FakeInvite>{};
  final _tasks = <String, Task>{};
  final _rewards = <String, Reward>{};
  final _redemptions = <_FakeRedemption>[];
  final _goals = <_FakeGoal>[];
  final _submissions = <_FakeSubmission>[];

  /// Foto bukti: baris submission_photos + isi file di "bucket" (path -> bytes).
  final _photos = <_FakePhoto>[];
  final _photoFiles = <String, Uint8List>{};

  /// Ledger poin sederhana; dompet lengkap (saldo, riwayat) di minggu 6.
  final _ledger = <_FakeTransaction>[];

  /// Catat transaksi poin (meniru _add_points).
  void _addPoints(String memberId, int amount, String type, String? reason, {String? refId, bool goal = false}) =>
      _ledger.add(
        _FakeTransaction(
          id: _id('tx'),
          memberId: memberId,
          amount: amount,
          type: type,
          reason: reason,
          refId: refId,
          goalBucket: goal,
          createdAt: _clock(),
        ),
      );

  int _balanceOf(String memberId) =>
      _ledger.where((t) => t.memberId == memberId && !t.goalBucket).fold(0, (sum, t) => sum + t.amount);

  String _id(String prefix) => '$prefix-${++_seq}';

  void _notifyFamily(String familyId) => _changes.add(familyId);

  AuthUser _requireUser() => _user ?? (throw const AppException('not_authenticated'));

  _FakeMember _requireAdmin(String familyId) {
    final user = _requireUser();
    return _members.values.firstWhere(
      (m) => m.member.familyId == familyId && m.member.role.isAdmin && m.logins.contains(user.id),
      orElse: () => throw const AppException('not_authorized'),
    );
  }

  void _requireFamilyMember(String familyId) {
    final user = _requireUser();
    final ok = _members.values.any((m) => m.member.familyId == familyId && m.logins.contains(user.id));
    if (!ok) throw const AppException('not_authorized');
  }

  /// Anggota yang sedang dipakai di "HP" ini (meniru _require_linked_member).
  _FakeMember _requireLinked(String memberId) {
    final user = _requireUser();
    final m = _members[memberId];
    if (m == null || !m.logins.contains(user.id)) throw const AppException('not_authorized');
    return m;
  }
}

class _FakeMember {
  _FakeMember(this.member);

  final Member member;
  final logins = <String>{};
  String? pin;

  Member get withConnection => Member(
    id: member.id,
    familyId: member.familyId,
    role: member.role,
    name: member.name,
    avatar: member.avatar,
    canEarn: member.canEarn,
    birthDate: member.birthDate,
    isConnected: logins.isNotEmpty,
  );
}

class _FakeInvite {
  _FakeInvite({required this.familyId, required this.role, required this.memberId, required this.expiresAt});

  final String familyId;
  final MemberRole role;
  final String? memberId;
  final DateTime expiresAt;
  String? usedBy;
}

class _FakeSubmission {
  _FakeSubmission({
    required this.id,
    required this.familyId,
    required this.memberId,
    required this.taskId,
    required this.status,
    required this.pointsSnapshot,
    required this.forDate,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String familyId;
  final String memberId;
  final String taskId;
  SubmissionStatus status;
  final int pointsSnapshot;
  final DateTime forDate;
  final DateTime createdAt;
  final String? note;
  String? reviewedBy;
  String? rejectReason;
  bool reversed = false;

  /// Verifikasi otomatis (bisa dibatalkan admin dalam 24 jam).
  bool isAuto = false;

  SubmissionSummary get summary => SubmissionSummary(
    id: id,
    taskId: taskId,
    status: status,
    forDate: forDate,
    createdAt: createdAt,
    reason: rejectReason,
    reversed: reversed,
  );
}

class _FakePhoto {
  _FakePhoto({required this.submissionId, required this.photo});

  final String submissionId;
  final ProofPhoto photo;
  bool deleted = false;
}

class _FakeTransaction {
  _FakeTransaction({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.reason,
    this.refId,
    this.goalBucket = false,
  });

  final String id;
  final String memberId;
  final int amount;
  final String type;
  final String? reason;
  final String? refId;
  final bool goalBucket;
  final DateTime createdAt;

  LedgerEntry get entry => LedgerEntry(
    id: id,
    amount: amount,
    type: LedgerType.parse(type),
    reason: reason,
    refId: refId,
    goalBucket: goalBucket,
    createdAt: createdAt,
  );
}

class _FakeRedemption {
  _FakeRedemption({
    required this.id,
    required this.familyId,
    required this.rewardId,
    required this.memberId,
    required this.cost,
    required this.status,
    required this.forDate,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String rewardId;
  final String memberId;
  final int cost;
  RedemptionStatus status;
  final DateTime forDate;
  final DateTime createdAt;
  DateTime? sessionStartedAt;
  DateTime? sessionEndsAt;
  String? rejectReason;
  String? reviewedBy;
}

class _FakeGoal {
  _FakeGoal({required this.id, required this.memberId, required this.rewardId});

  final String id;
  final String memberId;
  final String rewardId;
  bool isActive = true;
  DateTime? achievedAt;
}
