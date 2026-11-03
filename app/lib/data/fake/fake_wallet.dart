part of 'fake_repository.dart';

/// Dompet: meniru view member_balances, _recompute_streak, RPC adjust_points & reverse_auto_task.
mixin _FakeWallet on _FakeState implements WalletRepository {
  _FakeMember _requireMember(String memberId) => _members[memberId] ?? (throw const AppException('member_not_found'));

  @override
  Future<WalletSummary> wallet(Member member) async {
    _requireFamilyMember(member.familyId);
    final today = familyToday(_families[member.familyId] ?? 'Asia/Jakarta', now: _clock());
    final submissions = [
      for (final s in _submissions)
        if (s.memberId == member.id) s.summary,
    ];
    final available = _balanceOf(member.id);
    final debits = _ledger.where((t) => t.memberId == member.id && t.amount < 0);
    return WalletSummary(
      balance: Balance(
        available: available,
        onHold: _redemptions
            .where((r) => r.memberId == member.id && r.status == RedemptionStatus.requested)
            .fold(0, (sum, r) => sum + r.cost),
        goalSaved: _ledger.where((t) => t.memberId == member.id && t.goalBucket).fold(0, (sum, t) => sum + t.amount),
      ),
      streak: computeStreak(submissions, today),
      week: weekActivity(submissions, today),
      today: today,
      debtReason: available < 0 && debits.isNotEmpty ? debits.last.reason : null,
    );
  }

  @override
  Future<List<LedgerEntry>> history(String memberId, {int limit = 100}) async {
    _requireFamilyMember(_requireMember(memberId).member.familyId);
    return [
      for (final t in _ledger.reversed)
        if (t.memberId == memberId) t.entry,
    ].take(limit).toList();
  }

  @override
  Future<void> adjustPoints({required String memberId, required int amount, required String reason}) async {
    final target = _requireMember(memberId);
    final admin = _requireAdmin(target.member.familyId);
    if (admin.member.id == memberId) throw const AppException('cannot_review_own');
    if (!target.member.canEarn) throw const AppException('member_cannot_earn');
    if (amount == 0 || amount.abs() > 1000000) throw const AppException('invalid_amount');
    if (reason.trim().isEmpty) throw const AppException('reason_required');
    if (amount < 0 && _balanceOf(memberId) + amount < 0) throw const AppException('insufficient_points');
    _addPoints(memberId, amount, amount > 0 ? 'bonus' : 'penalty', reason.trim());
    _notifyFamily(target.member.familyId);
  }

  @override
  Future<Set<String>> reversibleSubmissions(String memberId) async {
    _requireFamilyMember(_requireMember(memberId).member.familyId);
    final now = _clock();
    return {
      for (final s in _submissions)
        if (s.memberId == memberId &&
            s.isAuto &&
            s.status == SubmissionStatus.approved &&
            !s.reversed &&
            now.difference(s.createdAt) <= const Duration(hours: 24))
          s.id,
    };
  }

  @override
  Future<void> reverseAutoTask({required String submissionId, required String reason}) async {
    final sub = _submissions.firstWhere(
      (s) => s.id == submissionId,
      orElse: () => throw const AppException('not_found'),
    );
    final admin = _requireAdmin(sub.familyId);
    if (admin.member.id == sub.memberId) throw const AppException('cannot_review_own');
    if (!sub.isAuto || sub.status != SubmissionStatus.approved || sub.reversed) {
      throw const AppException('not_reversible');
    }
    if (_clock().difference(sub.createdAt) > const Duration(hours: 24)) {
      throw const AppException('reversal_window_passed');
    }
    if (reason.trim().isEmpty) throw const AppException('reason_required');
    sub
      ..reversed = true
      ..reviewedBy = admin.member.id
      ..rejectReason = reason.trim();
    _addPoints(sub.memberId, -sub.pointsSnapshot, 'reversal', reason.trim(), refId: sub.id);
    _notifyFamily(sub.familyId);
  }
}
