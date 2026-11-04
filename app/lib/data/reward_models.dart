/// Hadiah, penukaran, dan goal (PRD modul 6 & 7). Kolom mengikuti tabel rewards / redemptions / goals.
library;

import '../l10n/strings.dart';

enum RewardType {
  instant('instant'),
  goal('goal');

  const RewardType(this.db);

  final String db;

  String get label => this == instant ? S.current.rewardInstantShort : S.current.goal;

  static RewardType parse(String value) => values.firstWhere((t) => t.db == value);
}

/// Isi form hadiah (H-01, H-02, H-04). Harga hadiah lama diubah lewat update_reward_price.
class RewardInput {
  const RewardInput({
    required this.title,
    required this.cost,
    required this.type,
    this.icon,
    this.durationMinutes,
    this.maxPerDay,
    this.stock,
    this.needsApproval = true,
  });

  final String title;
  final int cost;
  final RewardType type;
  final String? icon;

  /// Menit sesi screen time (hadiah instan); null = bukan screen time.
  final int? durationMinutes;

  /// null = tanpa batas.
  final int? maxPerDay;
  final int? stock;
  final bool needsApproval;

  String? validate() {
    final name = title.trim();
    if (name.isEmpty) return S.current.rewardNameRequired;
    if (name.length > 60) return S.current.rewardNameTooLong;
    if (cost < 1 || cost > 10000000) return S.current.rewardCostRange;
    if (durationMinutes != null && (durationMinutes! < 1 || durationMinutes! > 1440)) return S.current.durationRange;
    if (maxPerDay != null && maxPerDay! < 1) return S.current.rewardDailyLimitMin;
    if (stock != null && stock! < 0) return S.current.stockNotNegative;
    return null;
  }

  /// Kolom tabel rewards selain harga (cost), id, family_id.
  Map<String, dynamic> toRow() => {
    'title': title.trim(),
    'icon': icon,
    'duration_minutes': type == RewardType.instant ? durationMinutes : null,
    'max_per_day': maxPerDay,
    'stock': stock,
    'needs_approval': needsApproval,
  };
}

class Reward extends RewardInput {
  const Reward({
    required this.id,
    required this.familyId,
    required super.title,
    required super.cost,
    required super.type,
    super.icon,
    super.durationMinutes,
    super.maxPerDay,
    super.stock,
    super.needsApproval,
    this.isArchived = false,
    this.pendingCost,
    this.costEffectiveAt,
  });

  factory Reward.fromRow(Map<String, dynamic> row) => Reward(
    id: row['id'] as String,
    familyId: row['family_id'] as String,
    title: row['title'] as String,
    cost: row['cost'] as int,
    type: RewardType.parse(row['type'] as String),
    icon: row['icon'] as String?,
    durationMinutes: row['duration_minutes'] as int?,
    maxPerDay: row['max_per_day'] as int?,
    stock: row['stock'] as int?,
    needsApproval: row['needs_approval'] as bool? ?? true,
    isArchived: row['is_archived'] as bool? ?? false,
    pendingCost: row['pending_cost'] as int?,
    costEffectiveAt: row['cost_effective_at'] == null
        ? null
        : DateTime.parse(row['cost_effective_at'] as String).toLocal(),
  );

  factory Reward.fromInput(
    RewardInput input, {
    required String id,
    required String familyId,
    bool isArchived = false,
    int? cost,
    int? pendingCost,
    DateTime? costEffectiveAt,
  }) => Reward(
    id: id,
    familyId: familyId,
    title: input.title.trim(),
    cost: cost ?? input.cost,
    type: input.type,
    icon: input.icon,
    durationMinutes: input.type == RewardType.instant ? input.durationMinutes : null,
    maxPerDay: input.maxPerDay,
    stock: input.stock,
    needsApproval: input.needsApproval,
    isArchived: isArchived,
    pendingCost: pendingCost,
    costEffectiveAt: costEffectiveAt,
  );

  final String id;
  final String familyId;
  final bool isArchived;

  /// Kenaikan harga yang menunggu 7 hari (aturan bisnis 6).
  final int? pendingCost;
  final DateTime? costEffectiveAt;

  bool get isScreenTime => durationMinutes != null;

  /// Ringkasan untuk daftar, mis. "30 menit · maks 2×/hari · perlu persetujuan".
  String get rulesLabel => [
    if (type == RewardType.goal) S.current.rewardGoalSaved,
    if (durationMinutes != null) S.current.minutesAmount(durationMinutes!),
    if (maxPerDay != null) S.current.maxPerDayShortLabel(maxPerDay!),
    if (stock != null) S.current.stockAmount(stock!),
    needsApproval ? S.current.needsApprovalShort : S.current.immediate,
  ].join(' · ');
}

enum RedemptionStatus {
  requested('requested'),
  approved('approved'),
  fulfilled('fulfilled'),
  rejected('rejected'),
  cancelled('cancelled');

  const RedemptionStatus(this.db);

  final String db;

  static RedemptionStatus parse(String value) => values.firstWhere((s) => s.db == value);

  bool get isOpen => this == requested || this == approved;
}

/// Penukaran hadiah (H-03–H-06): Diajukan → Disetujui → Diberikan, atau Ditolak / Dibatalkan.
class Redemption {
  const Redemption({
    required this.id,
    required this.rewardId,
    required this.rewardTitle,
    required this.rewardType,
    required this.memberId,
    required this.memberName,
    required this.cost,
    required this.status,
    required this.createdAt,
    this.rewardIcon,
    this.memberAvatar,
    this.durationMinutes,
    this.sessionStartedAt,
    this.sessionEndsAt,
    this.rejectReason,
  });

  /// Baris redemptions dengan relasi `reward:rewards(...)` dan `member:members!member_id(...)`.
  factory Redemption.fromRow(Map<String, dynamic> row) {
    final reward = row['reward'] as Map<String, dynamic>;
    final member = row['member'] as Map<String, dynamic>;
    DateTime? time(String key) => row[key] == null ? null : DateTime.parse(row[key] as String).toLocal();
    return Redemption(
      id: row['id'] as String,
      rewardId: row['reward_id'] as String,
      rewardTitle: reward['title'] as String,
      rewardIcon: reward['icon'] as String?,
      rewardType: RewardType.parse(reward['type'] as String),
      durationMinutes: reward['duration_minutes'] as int?,
      memberId: row['member_id'] as String,
      memberName: member['name'] as String,
      memberAvatar: member['avatar'] as String?,
      cost: row['cost_snapshot'] as int,
      status: RedemptionStatus.parse(row['status'] as String),
      createdAt: time('created_at')!,
      sessionStartedAt: time('session_started_at'),
      sessionEndsAt: time('session_ends_at'),
      rejectReason: row['reject_reason'] as String?,
    );
  }

  final String id;
  final String rewardId;
  final String rewardTitle;
  final String? rewardIcon;
  final RewardType rewardType;
  final int? durationMinutes;
  final String memberId;
  final String memberName;
  final String? memberAvatar;
  final int cost;
  final RedemptionStatus status;
  final DateTime createdAt;
  final DateTime? sessionStartedAt;
  final DateTime? sessionEndsAt;
  final String? rejectReason;

  /// Sesi screen time sedang berjalan (H-06).
  bool sessionActive(DateTime now) =>
      status == RedemptionStatus.approved && sessionEndsAt != null && now.isBefore(sessionEndsAt!);

  /// Disetujui tapi belum diberikan & bukan sesi screen time: orang tua perlu menandai "sudah diberikan".
  bool get awaitingFulfilment => status == RedemptionStatus.approved && sessionEndsAt == null;
}

enum RedemptionAction { approve, reject, fulfill }

/// Goal aktif anak (G-01, G-02).
class GoalProgress {
  const GoalProgress({
    required this.goalId,
    required this.reward,
    required this.saved,
    required this.available,
    this.daysLeft,
  });

  final String goalId;
  final Reward reward;

  /// Poin di kantong tabungan goal (G-03).
  final int saved;

  /// Saldo tersedia (bisa ikut dipakai saat menukar goal).
  final int available;

  /// Estimasi hari sampai cukup dari rata-rata poin harian; null bila belum bisa diperkirakan.
  final int? daysLeft;

  /// Poin yang dihitung untuk goal: tabungan + saldo tersedia (tidak negatif).
  int get progress => saved + (available > 0 ? available : 0);

  bool get reached => progress >= reward.cost;
}

/// Estimasi hari menuju goal (G-02): sisa poin dibagi rata-rata poin masuk per hari (14 hari terakhir).
int? estimateDaysLeft({required int remaining, required int earnedLast14Days}) {
  if (remaining <= 0) return 0;
  if (earnedLast14Days <= 0) return null;
  final perDay = earnedLast14Days / 14;
  return (remaining / perDay).ceil();
}
