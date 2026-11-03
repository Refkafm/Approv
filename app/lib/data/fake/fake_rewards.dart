part of 'fake_repository.dart';

/// Hadiah & goal: meniru RPC redeem_reward, review_redemption, cancel_redemption, set_goal, save_to_goal,
/// update_reward_price, dan cron finish_screen_sessions.
mixin _FakeRewards on _FakeState implements RewardRepository {
  Reward _requireReward(String id) => _rewards[id] ?? (throw const AppException('not_found'));

  _FakeRedemption _requireRedemption(String id) =>
      _redemptions.firstWhere((r) => r.id == id, orElse: () => throw const AppException('not_found'));

  _FakeGoal? _activeGoalOf(String memberId) => _goals.where((g) => g.memberId == memberId && g.isActive).firstOrNull;

  int _goalBalanceOf(String memberId) =>
      _ledger.where((t) => t.memberId == memberId && t.goalBucket).fold(0, (sum, t) => sum + t.amount);

  /// Salinan hadiah dengan stok/arsip/harga baru (Reward tidak bisa diubah).
  Reward _copyReward(Reward r, {int? stock, bool? isArchived, int? cost, int? pendingCost, DateTime? effectiveAt}) =>
      Reward.fromInput(
        RewardInput(
          title: r.title,
          cost: r.cost,
          type: r.type,
          icon: r.icon,
          durationMinutes: r.durationMinutes,
          maxPerDay: r.maxPerDay,
          stock: stock ?? r.stock,
          needsApproval: r.needsApproval,
        ),
        id: r.id,
        familyId: r.familyId,
        isArchived: isArchived ?? r.isArchived,
        cost: cost ?? r.cost,
        pendingCost: pendingCost,
        costEffectiveAt: effectiveAt,
      );

  /// Meniru cron finish_screen_sessions: sesi yang sudah habis ditandai diberikan.
  void _tickSessions() {
    final now = _clock();
    for (final r in _redemptions) {
      if (r.status == RedemptionStatus.approved && r.sessionEndsAt != null && !now.isBefore(r.sessionEndsAt!)) {
        r.status = RedemptionStatus.fulfilled;
      }
    }
  }

  Redemption _toRedemption(_FakeRedemption r) {
    final reward = _rewards[r.rewardId]!;
    final member = _members[r.memberId]!.member;
    return Redemption(
      id: r.id,
      rewardId: r.rewardId,
      rewardTitle: reward.title,
      rewardIcon: reward.icon,
      rewardType: reward.type,
      durationMinutes: reward.durationMinutes,
      memberId: r.memberId,
      memberName: member.name,
      memberAvatar: member.avatar,
      cost: r.cost,
      status: r.status,
      createdAt: r.createdAt,
      sessionStartedAt: r.sessionStartedAt,
      sessionEndsAt: r.sessionEndsAt,
      rejectReason: r.rejectReason,
    );
  }

  @override
  Future<List<Reward>> listRewards(String familyId, {bool archived = false}) async {
    _requireFamilyMember(familyId);
    return [
      for (final r in _rewards.values)
        if (r.familyId == familyId && r.isArchived == archived) r,
    ];
  }

  @override
  Future<Reward> createReward(String familyId, RewardInput input) async {
    _requireAdmin(familyId);
    if (input.validate() != null) throw const AppException('invalid_reward');
    final id = _id('reward');
    final reward = Reward.fromInput(input, id: id, familyId: familyId);
    _rewards[id] = reward;
    _notifyFamily(familyId);
    return reward;
  }

  @override
  Future<Reward> updateReward(String rewardId, RewardInput input) async {
    final old = _requireReward(rewardId);
    _requireAdmin(old.familyId);
    if (input.validate() != null) throw const AppException('invalid_reward');
    // Jenis & harga tidak ikut diubah (grant kolom di SQL); harga lewat updateRewardPrice
    final reward = Reward.fromInput(
      RewardInput(
        title: input.title,
        cost: old.cost,
        type: old.type,
        icon: input.icon,
        durationMinutes: input.durationMinutes,
        maxPerDay: input.maxPerDay,
        stock: input.stock,
        needsApproval: input.needsApproval,
      ),
      id: rewardId,
      familyId: old.familyId,
      isArchived: old.isArchived,
      pendingCost: old.pendingCost,
      costEffectiveAt: old.costEffectiveAt,
    );
    _rewards[rewardId] = reward;
    _notifyFamily(old.familyId);
    return reward;
  }

  @override
  Future<bool> updateRewardPrice(String rewardId, int cost) async {
    final old = _requireReward(rewardId);
    _requireAdmin(old.familyId);
    if (cost < 1 || cost > 10000000) throw const AppException('invalid_cost');
    final scheduled = cost > old.cost && _goals.any((g) => g.rewardId == rewardId && g.isActive);
    _rewards[rewardId] = scheduled
        ? _copyReward(old, pendingCost: cost, effectiveAt: _clock().add(const Duration(days: 7)))
        : _copyReward(old, cost: cost);
    _notifyFamily(old.familyId);
    return scheduled;
  }

  @override
  Future<void> setRewardArchived(String rewardId, {required bool archived}) async {
    final old = _requireReward(rewardId);
    _requireAdmin(old.familyId);
    _rewards[rewardId] = _copyReward(
      old,
      isArchived: archived,
      pendingCost: old.pendingCost,
      effectiveAt: old.costEffectiveAt,
    );
    _notifyFamily(old.familyId);
  }

  @override
  Future<void> redeemReward({required Member member, required String rewardId}) async {
    final me = _requireLinked(member.id);
    if (!me.member.canEarn) throw const AppException('member_cannot_earn');
    final reward = _rewards[rewardId];
    if (reward == null || reward.familyId != member.familyId || reward.isArchived) {
      throw const AppException('reward_not_available');
    }
    if (reward.stock != null && reward.stock! <= 0) throw const AppException('out_of_stock');

    final today = familyToday(_families[member.familyId] ?? 'Asia/Jakarta', now: _clock());
    if (reward.maxPerDay != null) {
      final used = _redemptions.where(
        (r) =>
            r.rewardId == rewardId &&
            r.memberId == member.id &&
            r.forDate == today &&
            r.status != RedemptionStatus.rejected &&
            r.status != RedemptionStatus.cancelled,
      );
      if (used.length >= reward.maxPerDay!) throw const AppException('reward_limit_reached');
    }

    // Hadiah goal: tabungan goal dipakai dulu, kekurangannya dari saldo tersedia
    final goal = _activeGoalOf(member.id);
    final fromGoal = reward.type == RewardType.goal && goal?.rewardId == rewardId
        ? _goalBalanceOf(member.id).clamp(0, reward.cost)
        : 0;
    final fromAvailable = reward.cost - fromGoal;
    if (fromAvailable > 0 && _balanceOf(member.id) < fromAvailable) throw const AppException('insufficient_points');

    final now = _clock();
    final approved = !reward.needsApproval;
    final redemption = _FakeRedemption(
      id: _id('redemption'),
      familyId: member.familyId,
      rewardId: rewardId,
      memberId: member.id,
      cost: reward.cost,
      status: approved ? RedemptionStatus.approved : RedemptionStatus.requested,
      forDate: today,
      createdAt: now,
    );
    if (approved && reward.durationMinutes != null) {
      redemption
        ..sessionStartedAt = now
        ..sessionEndsAt = now.add(Duration(minutes: reward.durationMinutes!));
    }
    _redemptions.add(redemption);
    if (fromGoal > 0) _addPoints(member.id, -fromGoal, 'redeem_hold', reward.title, refId: redemption.id, goal: true);
    if (fromAvailable > 0) _addPoints(member.id, -fromAvailable, 'redeem_hold', reward.title, refId: redemption.id);
    if (reward.stock != null) {
      _rewards[rewardId] = _copyReward(
        reward,
        stock: reward.stock! - 1,
        pendingCost: reward.pendingCost,
        effectiveAt: reward.costEffectiveAt,
      );
    }
    _notifyFamily(member.familyId);
  }

  /// Kembalikan poin yang ditahan; dari kantong goal kembali ke goal bila goal itu masih aktif.
  void _release(_FakeRedemption r, String reason) {
    final goalActive = _activeGoalOf(r.memberId)?.rewardId == r.rewardId;
    for (final hold in _ledger.where((t) => t.refId == r.id && t.type == 'redeem_hold').toList()) {
      _addPoints(r.memberId, -hold.amount, 'redeem_release', reason, refId: r.id, goal: hold.goalBucket && goalActive);
    }
    final reward = _rewards[r.rewardId]!;
    if (reward.stock != null) {
      _rewards[r.rewardId] = _copyReward(
        reward,
        stock: reward.stock! + 1,
        pendingCost: reward.pendingCost,
        effectiveAt: reward.costEffectiveAt,
      );
    }
  }

  @override
  Future<void> cancelRedemption(String redemptionId) async {
    final r = _requireRedemption(redemptionId);
    _requireLinked(r.memberId);
    if (r.status != RedemptionStatus.requested) throw const AppException('not_cancellable');
    r.status = RedemptionStatus.cancelled;
    _release(r, 'Dibatalkan');
    _notifyFamily(r.familyId);
  }

  @override
  Future<List<Redemption>> memberRedemptions(String memberId) async {
    final member = _members[memberId] ?? (throw const AppException('member_not_found'));
    _requireFamilyMember(member.member.familyId);
    _tickSessions();
    return [
      for (final r in _redemptions.reversed)
        if (r.memberId == memberId) _toRedemption(r),
    ];
  }

  @override
  Future<List<Redemption>> openRedemptions(String familyId) async {
    _requireAdmin(familyId);
    _tickSessions();
    return [
      for (final r in _redemptions)
        if (r.familyId == familyId &&
            (r.status == RedemptionStatus.requested ||
                (r.status == RedemptionStatus.approved && r.sessionEndsAt == null)))
          _toRedemption(r),
    ];
  }

  @override
  Future<void> reviewRedemption(String redemptionId, RedemptionAction action, {String? reason}) async {
    final r = _requireRedemption(redemptionId);
    final admin = _requireAdmin(r.familyId);
    if (admin.member.id == r.memberId) throw const AppException('cannot_review_own');
    _tickSessions();
    if (!r.status.isOpen || (action == RedemptionAction.approve && r.status != RedemptionStatus.requested)) {
      throw AppException('already_reviewed', detail: _members[r.reviewedBy]?.member.name);
    }
    final reward = _rewards[r.rewardId]!;
    final now = _clock();
    switch (action) {
      case RedemptionAction.approve:
        r.status = RedemptionStatus.approved;
        if (reward.durationMinutes != null) {
          r
            ..sessionStartedAt = now
            ..sessionEndsAt = now.add(Duration(minutes: reward.durationMinutes!));
        }
      case RedemptionAction.reject:
        final why = reason?.trim() ?? '';
        if (why.isEmpty) throw const AppException('reason_required');
        r
          ..status = RedemptionStatus.rejected
          ..rejectReason = why;
        _release(r, why);
      case RedemptionAction.fulfill:
        r.status = RedemptionStatus.fulfilled;
        final goal = _activeGoalOf(r.memberId);
        if (reward.type == RewardType.goal && goal?.rewardId == r.rewardId) {
          goal!
            ..isActive = false
            ..achievedAt = now;
          _unsaveAll(r.memberId, 'Sisa tabungan goal', goal.id);
        }
    }
    r.reviewedBy = admin.member.id;
    _notifyFamily(r.familyId);
  }

  void _unsaveAll(String memberId, String reason, String goalId) {
    final saved = _goalBalanceOf(memberId);
    if (saved > 0) {
      _addPoints(memberId, -saved, 'goal_unsave', reason, refId: goalId, goal: true);
      _addPoints(memberId, saved, 'goal_unsave', reason, refId: goalId);
    }
  }

  @override
  Future<GoalProgress?> activeGoal(Member member) async {
    _requireFamilyMember(member.familyId);
    final goal = _activeGoalOf(member.id);
    if (goal == null) return null;
    final reward = _rewards[goal.rewardId]!;
    final since = _clock().subtract(const Duration(days: 14));
    final earned = _ledger
        .where(
          (t) =>
              t.memberId == member.id &&
              !t.goalBucket &&
              t.amount > 0 &&
              (t.type == 'task' || t.type == 'bonus' || t.type == 'streak') &&
              t.createdAt.isAfter(since),
        )
        .fold(0, (sum, t) => sum + t.amount);
    final saved = _goalBalanceOf(member.id);
    final available = _balanceOf(member.id);
    final progress = saved + (available > 0 ? available : 0);
    return GoalProgress(
      goalId: goal.id,
      reward: reward,
      saved: saved,
      available: available,
      daysLeft: estimateDaysLeft(remaining: reward.cost - progress, earnedLast14Days: earned),
    );
  }

  @override
  Future<void> setGoal({required Member member, required String rewardId}) async {
    final me = _requireLinked(member.id);
    if (!me.member.canEarn) throw const AppException('member_cannot_earn');
    final reward = _rewards[rewardId];
    if (reward == null || reward.familyId != member.familyId || reward.type != RewardType.goal || reward.isArchived) {
      throw const AppException('reward_not_available');
    }
    final current = _activeGoalOf(member.id);
    if (current?.rewardId == rewardId) return;
    if (current != null) {
      current.isActive = false;
      _unsaveAll(member.id, 'Ganti goal', current.id);
    }
    _goals.add(_FakeGoal(id: _id('goal'), memberId: member.id, rewardId: rewardId));
    _notifyFamily(member.familyId);
  }

  @override
  Future<void> saveToGoal({required Member member, required int amount}) async {
    _requireLinked(member.id);
    final goal = _activeGoalOf(member.id) ?? (throw const AppException('no_active_goal'));
    if (amount == 0) throw const AppException('invalid_amount');
    if (amount > 0) {
      if (_balanceOf(member.id) < amount) throw const AppException('insufficient_points');
      _addPoints(member.id, -amount, 'goal_save', null, refId: goal.id);
      _addPoints(member.id, amount, 'goal_save', null, refId: goal.id, goal: true);
    } else {
      if (_goalBalanceOf(member.id) < -amount) throw const AppException('insufficient_points');
      _addPoints(member.id, amount, 'goal_unsave', null, refId: goal.id, goal: true);
      _addPoints(member.id, -amount, 'goal_unsave', null, refId: goal.id);
    }
    _notifyFamily(member.familyId);
  }
}
