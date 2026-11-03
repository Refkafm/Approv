part of 'supabase_repository.dart';

mixin _SupabaseWallet on _SupabaseBase implements WalletRepository {
  @override
  Future<WalletSummary> wallet(Member member) => _guard(() async {
    final family = await _client.from('families').select('timezone').eq('id', member.familyId).single();
    final today = familyToday(family['timezone'] as String);

    final balanceRow = await _client.from('member_balances').select().eq('member_id', member.id).maybeSingle();
    final balance = balanceRow == null ? const Balance(available: 0) : Balance.fromRow(balanceRow);

    // Streak dihitung server (_recompute_streak); aktivitas per hari dari laporan minggu ini
    final streakRow = await _client.from('streaks').select('current_count').eq('member_id', member.id).maybeSingle();
    final submissions = await _client
        .from('task_submissions')
        .select('id, task_id, status, for_date, created_at, reversed_at')
        .eq('member_id', member.id)
        .gte('for_date', _isoDate(weekStart(today)));

    String? debtReason;
    if (balance.available < 0) {
      final last = await _client
          .from('point_transactions')
          .select('reason')
          .eq('member_id', member.id)
          .lt('amount', 0)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      debtReason = last?['reason'] as String?;
    }

    return WalletSummary(
      balance: balance,
      streak: streakRow?['current_count'] as int? ?? 0,
      week: weekActivity(submissions.map(SubmissionSummary.fromRow).toList(), today),
      today: today,
      debtReason: debtReason,
    );
  });

  @override
  Future<List<LedgerEntry>> history(String memberId, {int limit = 100}) => _guard(() async {
    final rows = await _client
        .from('point_transactions')
        .select('id, amount, type, reason, ref_id, bucket, created_at')
        .eq('member_id', memberId)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    return rows.map(LedgerEntry.fromRow).toList();
  });

  @override
  Future<void> adjustPoints({required String memberId, required int amount, required String reason}) => _guard(
    () => _client.rpc('adjust_points', params: {'p_member_id': memberId, 'p_amount': amount, 'p_reason': reason}),
  );

  @override
  Future<Set<String>> reversibleSubmissions(String memberId) => _guard(() async {
    final since = DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();
    final rows = await _client
        .from('task_submissions')
        .select('id')
        .eq('member_id', memberId)
        .eq('is_auto', true)
        .eq('status', 'approved')
        .isFilter('reversed_at', null)
        .gte('created_at', since);
    return {for (final r in rows) r['id'] as String};
  });

  @override
  Future<void> reverseAutoTask({required String submissionId, required String reason}) =>
      _guard(() => _client.rpc('reverse_auto_task', params: {'p_submission_id': submissionId, 'p_reason': reason}));
}
