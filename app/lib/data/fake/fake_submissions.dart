part of 'fake_repository.dart';

/// Laporan & persetujuan: meniru RPC submit_task, resubmit_photos, review_submission, dan RLS foto.
mixin _FakeSubmissions on _FakeState implements SubmissionRepository {
  /// Meniru _insert_photos: jumlah & jenis foto, galeri hanya bila diizinkan, file disimpan di "bucket".
  void _storePhotos(Task task, Member member, String submissionId, List<PhotoCapture> photos) {
    if (!task.needsPhoto) {
      if (photos.isNotEmpty) throw const AppException('photos_not_allowed');
      return;
    }
    if (photos.length > 6) throw const AppException('too_many_photos');
    if (missingPhotosLabel(photos: photos, minPhotos: task.minPhotos, beforeAfter: task.beforeAfter) != null) {
      throw const AppException('photos_required');
    }
    if (photos.any((p) => p.origin == PhotoOrigin.gallery && !task.allowGallery)) {
      throw const AppException('invalid_photo');
    }
    for (final p in photos) {
      final path = '${member.familyId}/${member.id}/${_id('photo')}.jpg';
      _photoFiles[path] = p.bytes;
      _photos.add(
        _FakePhoto(
          submissionId: submissionId,
          photo: ProofPhoto(id: _id('proof'), kind: p.kind, path: path, takenAt: p.takenAt, origin: p.origin),
        ),
      );
    }
  }

  @override
  Future<void> submitTask({
    required Member member,
    required String taskId,
    String? note,
    List<PhotoCapture> photos = const [],
    DateTime? reportedAt,
  }) async {
    if (debugOffline) throw const AppException('offline');
    final me = _requireLinked(member.id);
    if (!me.member.canEarn) throw const AppException('member_cannot_earn');
    final task = _tasks[taskId];
    if (task == null || task.familyId != member.familyId || task.isArchived) {
      throw const AppException('task_not_available');
    }
    if (!task.isFor(member.id)) throw const AppException('task_not_assigned');

    // Sama dengan submit_task: waktu lapor dari antrean offline dibatasi 24 jam ke belakang
    final now = _clock();
    final earliest = now.subtract(const Duration(hours: 24));
    var at = reportedAt ?? now;
    if (at.isAfter(now)) at = now;
    if (at.isBefore(earliest)) at = earliest;
    final today = familyToday(_families[member.familyId] ?? 'Asia/Jakarta', now: at);
    final state = buildTodayTasks(
      tasks: [task],
      submissions: [
        for (final s in _submissions)
          if (s.memberId == member.id) s.summary,
      ],
      memberId: member.id,
      today: today,
    ).single;
    if (!state.scheduledToday) throw const AppException('task_not_today');
    if (!state.canReport) throw const AppException('task_limit_reached');

    final auto = task.verification == TaskVerification.auto;
    final trimmed = note?.trim();
    final submissionId = _id('submission');
    _storePhotos(task, member, submissionId, photos);
    _submissions.add(
      _FakeSubmission(
        id: submissionId,
        familyId: task.familyId,
        memberId: member.id,
        taskId: taskId,
        status: auto ? SubmissionStatus.approved : SubmissionStatus.pending,
        pointsSnapshot: task.points,
        forDate: today,
        createdAt: _clock(),
        note: (trimmed?.isEmpty ?? true) ? null : trimmed,
      )..isAuto = auto,
    );
    if (auto) _addPoints(member.id, task.points, 'task', task.title, refId: submissionId);
    _notifyFamily(task.familyId);
  }

  @override
  Future<List<ReviewItem>> pendingReviews(String familyId) async {
    _requireAdmin(familyId);
    final pending = _submissions.where((s) => s.familyId == familyId && s.status == SubmissionStatus.pending).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return [
      for (final s in pending)
        ReviewItem(
          id: s.id,
          memberId: s.memberId,
          memberName: _members[s.memberId]!.member.name,
          memberAvatar: _members[s.memberId]!.member.avatar,
          taskTitle: _tasks[s.taskId]!.title,
          taskIcon: _tasks[s.taskId]!.icon,
          verification: _tasks[s.taskId]!.verification,
          points: s.pointsSnapshot,
          forDate: s.forDate,
          createdAt: s.createdAt,
          note: s.note,
          isFlagged: _clock().difference(s.createdAt) > const Duration(hours: 72),
        ),
    ];
  }

  @override
  Future<void> reviewSubmission(String submissionId, ReviewAction action, {String? reason, int bonus = 0}) async {
    final sub = _submissions.firstWhere(
      (s) => s.id == submissionId,
      orElse: () => throw const AppException('not_found'),
    );
    final admin = _requireAdmin(sub.familyId);
    if (admin.member.id == sub.memberId) throw const AppException('cannot_review_own');
    if (sub.status != SubmissionStatus.pending) {
      throw AppException('already_reviewed', detail: _members[sub.reviewedBy]?.member.name);
    }
    final task = _tasks[sub.taskId]!;
    final why = reason?.trim() ?? '';

    switch (action) {
      case ReviewAction.approve:
        if (bonus < 0 || bonus > 100000) throw const AppException('invalid_bonus');
        sub.status = SubmissionStatus.approved;
        _addPoints(sub.memberId, sub.pointsSnapshot, 'task', task.title, refId: sub.id);
        if (bonus > 0) _addPoints(sub.memberId, bonus, 'bonus', why.isEmpty ? 'Kerja bagus!' : why, refId: sub.id);
      case ReviewAction.reject:
        if (why.isEmpty) throw const AppException('reason_required');
        sub.status = SubmissionStatus.rejected;
        sub.rejectReason = why;
      case ReviewAction.retake:
        if (!task.needsPhoto) throw const AppException('retake_requires_photo');
        sub.status = SubmissionStatus.needsRetake;
        sub.rejectReason = why.isEmpty ? null : why;
    }
    sub.reviewedBy = admin.member.id;
    _notifyFamily(sub.familyId);
  }

  @override
  Future<void> resubmitPhotos({
    required Member member,
    required String submissionId,
    required List<PhotoCapture> photos,
  }) async {
    final sub = _submissions.firstWhere(
      (s) => s.id == submissionId,
      orElse: () => throw const AppException('not_found'),
    );
    _requireLinked(sub.memberId);
    if (sub.status != SubmissionStatus.needsRetake) throw const AppException('not_awaiting_retake');
    final old = _photos.where((p) => p.submissionId == submissionId && !p.deleted).toList();
    _storePhotos(_tasks[sub.taskId]!, member, submissionId, photos);
    for (final p in old) {
      p.deleted = true;
    }
    sub
      ..status = SubmissionStatus.pending
      ..reviewedBy = null;
    _notifyFamily(sub.familyId);
  }

  @override
  Future<List<ProofPhoto>> submissionPhotos(String submissionId) async {
    final sub = _submissions.firstWhere(
      (s) => s.id == submissionId,
      orElse: () => throw const AppException('not_found'),
    );
    _requireFamilyMember(sub.familyId);
    return [
      for (final p in _photos)
        if (p.submissionId == submissionId && !p.deleted) p.photo,
    ];
  }

  @override
  Future<ImageProvider> proofImage(ProofPhoto photo) async {
    final bytes = _photoFiles[photo.path];
    if (bytes == null) throw const AppException('not_found');
    return MemoryImage(bytes);
  }

  @override
  Stream<void> watchFamily(String familyId) => _changes.stream.where((id) => id == familyId).map((_) {});

  /// Untuk tes sampai dompet dibuat (minggu 6).
  int debugBalance(String memberId) => _balanceOf(memberId);
}
