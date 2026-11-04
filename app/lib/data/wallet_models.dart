/// Dompet poin (PRD modul 5). Saldo selalu dihitung dari ledger point_transactions.
library;

import '../l10n/strings.dart';

/// Baris view member_balances.
class Balance {
  const Balance({required this.available, this.goalSaved = 0, this.onHold = 0});

  factory Balance.fromRow(Map<String, dynamic> row) => Balance(
    available: row['available'] as int? ?? 0,
    goalSaved: row['goal_saved'] as int? ?? 0,
    onHold: row['on_hold'] as int? ?? 0,
  );

  /// Bisa negatif ("utang poin", aturan bisnis 3).
  final int available;
  final int goalSaved;

  /// Poin yang sedang ditahan untuk penukaran yang belum diproses.
  final int onHold;
}

enum LedgerType {
  task('task'),
  bonus('bonus'),
  penalty('penalty'),
  streak('streak'),
  redeemHold('redeem_hold'),
  redeemRelease('redeem_release'),
  reversal('reversal'),
  goalSave('goal_save'),
  goalUnsave('goal_unsave');

  const LedgerType(this.db);

  final String db;

  static LedgerType parse(String value) => values.firstWhere((t) => t.db == value);
}

/// Satu baris point_transactions (P-02).
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.reason,
    this.refId,
    this.goalBucket = false,
  });

  factory LedgerEntry.fromRow(Map<String, dynamic> row) => LedgerEntry(
    id: row['id'].toString(),
    amount: row['amount'] as int,
    type: LedgerType.parse(row['type'] as String),
    reason: row['reason'] as String?,
    refId: row['ref_id'] as String?,
    goalBucket: row['bucket'] == 'goal',
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );

  final String id;
  final int amount;
  final LedgerType type;
  final String? reason;

  /// task_submissions.id untuk tugas, redemptions.id untuk penukaran.
  final String? refId;

  /// Baris di kantong tabungan goal (bukan saldo tersedia).
  final bool goalBucket;
  final DateTime createdAt;

  /// Judul di riwayat; alasan selalu terlihat oleh anak (PRD aturan ekonomi "penalti selalu disertai alasan").
  String get title => switch (type) {
    LedgerType.task => reason ?? S.current.ledgerTask,
    LedgerType.bonus => S.current.ledgerBonus(reason ?? S.current.greatWork),
    LedgerType.penalty => S.current.ledgerPenalty(reason ?? '-'),
    LedgerType.streak => S.current.ledgerStreak,
    LedgerType.redeemHold => S.current.ledgerRedeem(reason ?? S.current.rewardFallback),
    LedgerType.redeemRelease => S.current.ledgerRefund(reason),
    LedgerType.reversal => S.current.ledgerReversal(reason ?? '-'),
    LedgerType.goalSave => S.current.ledgerGoalSave,
    LedgerType.goalUnsave => S.current.ledgerGoalUnsave,
  };
}

/// Aktivitas satu hari di minggu ini, untuk indikator streak.
enum DayActivity { success, pending, empty }

/// Ringkasan dompet seorang anak: saldo, streak, dan aktivitas Senin–Minggu minggu ini.
class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.streak,
    required this.week,
    required this.today,
    this.debtReason,
  });

  final Balance balance;
  final int streak;

  /// 7 hari, Senin sampai Minggu.
  final List<DayActivity> week;

  /// Hari ini di zona waktu keluarga.
  final DateTime today;

  /// Alasan transaksi terakhir yang membuat saldo negatif.
  final String? debtReason;
}
