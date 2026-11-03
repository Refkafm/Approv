part of 'supabase_repository.dart';

mixin _SupabaseRewards on _SupabaseBase implements RewardRepository {
  static const _redemptionColumns =
      'id, reward_id, member_id, cost_snapshot, status, created_at, session_started_at, session_ends_at, '
      'reject_reason, reward:rewards(title, icon, type, duration_minutes), member:members!member_id(name, avatar)';

  @override
  Future<List<Reward>> listRewards(String familyId, {bool archived = false}) => _guard(() async {
    final rows = await _client
        .from('rewards')
        .select()
        .eq('family_id', familyId)
        .eq('is_archived', archived)
        .order('created_at');
    return rows.map(Reward.fromRow).toList();
  });

  @override
  Future<Reward> createReward(String familyId, RewardInput input) => _guard(() async {
    final row = await _client
        .from('rewards')
        .insert({...input.toRow(), 'family_id': familyId, 'cost': input.cost, 'type': input.type.db})
        .select()
        .single();
    return Reward.fromRow(row);
  });

  @override
  Future<Reward> updateReward(String rewardId, RewardInput input) => _guard(() async {
    final row = await _client.from('rewards').update(input.toRow()).eq('id', rewardId).select().single();
    return Reward.fromRow(row);
  });

  @override
  Future<bool> updateRewardPrice(String rewardId, int cost) => _guard(() async {
    final result = await _client.rpc('update_reward_price', params: {'p_reward_id': rewardId, 'p_new_cost': cost});
    return result == 'scheduled';
  });

  @override
  Future<void> setRewardArchived(String rewardId, {required bool archived}) =>
      _guard(() => _client.from('rewards').update({'is_archived': archived}).eq('id', rewardId));

  @override
  Future<void> redeemReward({required Member member, required String rewardId}) =>
      _guard(() => _client.rpc('redeem_reward', params: {'p_reward_id': rewardId, 'p_member_id': member.id}));

  @override
  Future<void> cancelRedemption(String redemptionId) =>
      _guard(() => _client.rpc('cancel_redemption', params: {'p_redemption_id': redemptionId}));

  @override
  Future<List<Redemption>> memberRedemptions(String memberId) => _guard(() async {
    final rows = await _client
        .from('redemptions')
        .select(_redemptionColumns)
        .eq('member_id', memberId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(Redemption.fromRow).toList();
  });

  @override
  Future<List<Redemption>> openRedemptions(String familyId) => _guard(() async {
    final rows = await _client
        .from('redemptions')
        .select(_redemptionColumns)
        .eq('family_id', familyId)
        .or('status.eq.requested,and(status.eq.approved,session_ends_at.is.null)')
        .order('created_at');
    return rows.map(Redemption.fromRow).toList();
  });

  @override
  Future<void> reviewRedemption(String redemptionId, RedemptionAction action, {String? reason}) => _guard(
    () => _client.rpc(
      'review_redemption',
      params: {'p_redemption_id': redemptionId, 'p_action': action.name, 'p_reason': reason},
    ),
  );

  @override
  Future<GoalProgress?> activeGoal(Member member) => _guard(() async {
    final goal = await _client
        .from('goals')
        .select('id, reward:rewards(*)')
        .eq('member_id', member.id)
        .eq('is_active', true)
        .maybeSingle();
    if (goal == null) return null;
    final reward = Reward.fromRow(goal['reward'] as Map<String, dynamic>);

    final balance = await _client.from('member_balances').select().eq('member_id', member.id).maybeSingle();
    final saved = balance?['goal_saved'] as int? ?? 0;
    final available = balance?['available'] as int? ?? 0;

    final since = DateTime.now().toUtc().subtract(const Duration(days: 14)).toIso8601String();
    final earnedRows = await _client
        .from('point_transactions')
        .select('amount')
        .eq('member_id', member.id)
        .eq('bucket', 'available')
        .inFilter('type', ['task', 'bonus', 'streak'])
        .gt('amount', 0)
        .gte('created_at', since);
    final earned = earnedRows.fold<int>(0, (sum, r) => sum + (r['amount'] as int));
    final progress = saved + (available > 0 ? available : 0);

    return GoalProgress(
      goalId: goal['id'] as String,
      reward: reward,
      saved: saved,
      available: available,
      daysLeft: estimateDaysLeft(remaining: reward.cost - progress, earnedLast14Days: earned),
    );
  });

  @override
  Future<void> setGoal({required Member member, required String rewardId}) =>
      _guard(() => _client.rpc('set_goal', params: {'p_member_id': member.id, 'p_reward_id': rewardId}));

  @override
  Future<void> saveToGoal({required Member member, required int amount}) =>
      _guard(() => _client.rpc('save_to_goal', params: {'p_member_id': member.id, 'p_amount': amount}));
}
