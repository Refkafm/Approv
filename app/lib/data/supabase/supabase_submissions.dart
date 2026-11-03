part of 'supabase_repository.dart';

mixin _SupabaseSubmissions on _SupabaseBase implements SubmissionRepository {
  static const _bucket = 'proofs';

  /// Unggah ke {family_id}/{member_id}/{acak}.jpg (sesuai policy proofs_insert), lalu kembalikan
  /// parameter p_photos untuk RPC. Dicoba ulang 3× bila sinyal putus.
  ///
  /// Bila tetap gagal, laporan masuk antrean offline (data/report_queue.dart). File yang terunggah tapi
  /// laporannya gagal tersimpan belum dibersihkan otomatis (perlu Edge Function, lihat photos_to_purge).
  Future<List<Map<String, dynamic>>> _upload(Member member, List<PhotoCapture> photos) async {
    final result = <Map<String, dynamic>>[];
    for (final photo in photos) {
      final path = '${member.familyId}/${member.id}/${_randomName()}.jpg';
      await _withRetry(
        () => _client.storage
            .from(_bucket)
            .uploadBinary(path, photo.bytes, fileOptions: const FileOptions(contentType: 'image/jpeg')),
      );
      result.add({
        'path': path,
        'kind': photo.kind.db,
        'source': photo.origin.name,
        'taken_at': photo.takenAt.toUtc().toIso8601String(),
      });
    }
    return result;
  }

  Future<T> _withRetry<T>(Future<T> Function() run) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await run();
      } on Exception {
        if (attempt >= 3) throw const AppException('upload_failed');
        await Future<void>.delayed(Duration(seconds: attempt));
      }
    }
  }

  static String _randomName() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Future<void> submitTask({
    required Member member,
    required String taskId,
    String? note,
    List<PhotoCapture> photos = const [],
    DateTime? reportedAt,
  }) async {
    final uploaded = await _upload(member, photos);
    await _guard(
      () => _client.rpc(
        'submit_task',
        params: {
          'p_task_id': taskId,
          'p_member_id': member.id,
          'p_note': note,
          'p_photos': uploaded,
          'p_reported_at': reportedAt?.toUtc().toIso8601String(),
        },
      ),
    );
  }

  @override
  Future<void> resubmitPhotos({
    required Member member,
    required String submissionId,
    required List<PhotoCapture> photos,
  }) async {
    final uploaded = await _upload(member, photos);
    await _guard(() => _client.rpc('resubmit_photos', params: {'p_submission_id': submissionId, 'p_photos': uploaded}));
  }

  @override
  Future<List<ProofPhoto>> submissionPhotos(String submissionId) => _guard(() async {
    final rows = await _client
        .from('submission_photos')
        .select('id, kind, storage_path, taken_at, source')
        .eq('submission_id', submissionId)
        .isFilter('deleted_at', null)
        .order('created_at');
    return rows.map(ProofPhoto.fromRow).toList();
  });

  // Bucket privat: hanya bisa dibuka lewat URL bertanda tangan yang kedaluwarsa (PRD 4b)
  @override
  Future<ImageProvider> proofImage(ProofPhoto photo) async {
    try {
      final url = await _client.storage.from(_bucket).createSignedUrl(photo.path, 600);
      return NetworkImage(url);
    } on StorageException {
      throw const AppException('not_found');
    }
  }

  @override
  Future<List<ReviewItem>> pendingReviews(String familyId) => _guard(() async {
    final rows = await _client
        .from('task_submissions')
        .select(
          'id, member_id, note, points_snapshot, for_date, created_at, is_flagged, '
          'task:tasks(title, icon, verification), member:members!member_id(name, avatar)',
        )
        .eq('family_id', familyId)
        .eq('status', 'pending')
        .order('created_at');
    return rows.map(ReviewItem.fromRow).toList();
  });

  @override
  Future<void> reviewSubmission(String submissionId, ReviewAction action, {String? reason, int bonus = 0}) => _guard(
    () => _client.rpc(
      'review_submission',
      params: {'p_submission_id': submissionId, 'p_action': action.name, 'p_reason': reason, 'p_bonus': bonus},
    ),
  );

  // Butuh tabel-tabel di bawah ada di publication supabase_realtime (migration 000500–000900).
  // Semua layar berbagi satu channel per keluarga: server Realtime hanya mengenal satu join per topik,
  // jadi channel ganda bertopik sama saling memutus saat salah satu layar ditutup. Channel dibiarkan hidup
  // sampai keluar akun (leave + join ulang bertopik sama di saat berdekatan juga bisa bertabrakan).
  @override
  Stream<void> watchFamily(String familyId) => (_familyChanges[familyId] ??= _familyController(familyId)).stream;

  StreamController<void> _familyController(String familyId) {
    RealtimeChannel? channel;
    late final StreamController<void> controller;
    final filter = PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'family_id', value: familyId);
    controller = StreamController<void>.broadcast(
      onListen: () {
        if (channel != null) return;
        channel = _client.channel('family-$familyId-changes');
        for (final table in const [
          'tasks',
          'members',
          'task_submissions',
          'point_transactions',
          'redemptions',
          'goals',
          'rewards',
        ]) {
          channel!.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: filter,
            callback: (_) => controller.add(null),
          );
        }
        channel!.subscribe();
      },
    );
    return controller;
  }
}
