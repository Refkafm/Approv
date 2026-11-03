import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_exception.dart';
import 'models.dart';
import 'photo_models.dart';
import 'submission_repository.dart';

/// Laporan yang belum terkirim karena tidak ada sinyal (Rencana minggu 8, "antrean offline").
class PendingReport {
  const PendingReport({
    required this.id,
    required this.memberId,
    required this.taskId,
    required this.reportedAt,
    this.note,
    this.photos = const [],
  });

  factory PendingReport.fromJson(Map<String, dynamic> json) => PendingReport(
    id: json['id'] as String,
    memberId: json['member_id'] as String,
    taskId: json['task_id'] as String,
    reportedAt: DateTime.parse(json['reported_at'] as String),
    note: json['note'] as String?,
    photos: [
      for (final p in json['photos'] as List)
        PhotoCapture(
          bytes: base64Decode(p['bytes'] as String),
          kind: PhotoKind.parse(p['kind'] as String),
          origin: PhotoOrigin.values.byName(p['origin'] as String),
          takenAt: DateTime.parse(p['taken_at'] as String),
        ),
    ],
  );

  final String id;
  final String memberId;
  final String taskId;
  final DateTime reportedAt;
  final String? note;
  final List<PhotoCapture> photos;

  Map<String, dynamic> toJson() => {
    'id': id,
    'member_id': memberId,
    'task_id': taskId,
    'reported_at': reportedAt.toUtc().toIso8601String(),
    'note': note,
    'photos': [
      for (final p in photos)
        {
          'bytes': base64Encode(p.bytes),
          'kind': p.kind.db,
          'origin': p.origin.name,
          'taken_at': p.takenAt.toUtc().toIso8601String(),
        },
    ],
  };
}

/// Tempat menyimpan antrean supaya bertahan saat app ditutup.
abstract interface class ReportQueueStore {
  Future<List<PendingReport>> load();
  Future<void> save(List<PendingReport> reports);
}

/// Mode demo & tes: hanya di memori.
class MemoryReportQueueStore implements ReportQueueStore {
  List<PendingReport> _saved = const [];

  @override
  Future<List<PendingReport>> load() async => List.of(_saved);

  @override
  Future<void> save(List<PendingReport> reports) async => _saved = List.of(reports);
}

/// Satu file JSON (foto sudah dikompres ±200 KB, antrean biasanya hanya beberapa laporan).
class FileReportQueueStore implements ReportQueueStore {
  FileReportQueueStore(this.file);

  final File file;

  @override
  Future<List<PendingReport>> load() async {
    try {
      if (!await file.exists()) return [];
      final rows = jsonDecode(await file.readAsString()) as List;
      return [for (final row in rows) PendingReport.fromJson(row as Map<String, dynamic>)];
    } on FormatException {
      // File rusak (mis. app mati saat menulis): lebih baik kosong daripada app gagal dibuka
      return [];
    }
  }

  @override
  Future<void> save(List<PendingReport> reports) async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode([for (final r in reports) r.toJson()]));
    await tmp.rename(file.path);
  }
}

/// Mengirim laporan; bila tidak ada sinyal, menyimpannya dan mengirim ulang nanti dengan waktu lapor
/// aslinya (submit_task p_reported_at). Laporan > 24 jam atau yang ditolak server dibuang.
class ReportQueue extends ChangeNotifier {
  ReportQueue(this._repository, {ReportQueueStore? store, DateTime Function()? clock})
    : _store = store ?? MemoryReportQueueStore(),
      _clock = clock ?? DateTime.now;

  final SubmissionRepository _repository;
  final ReportQueueStore _store;
  final DateTime Function() _clock;

  static const maxAge = Duration(hours: 24);
  static const _retryable = {'offline', 'upload_failed'};

  List<PendingReport> _items = [];
  bool _flushing = false;
  int _seq = 0;

  /// Pesan untuk laporan antrean yang akhirnya tidak bisa dikirim (ditampilkan sekali lalu dihapus).
  String? droppedMessage;

  List<PendingReport> pendingFor(String memberId) => [
    for (final r in _items)
      if (r.memberId == memberId) r,
  ];

  bool isQueued(String memberId, String taskId) => _items.any((r) => r.memberId == memberId && r.taskId == taskId);

  Future<void> load() async {
    _items = await _store.load();
    notifyListeners();
  }

  /// true = terkirim, false = disimpan di antrean. AppException lain diteruskan ke layar.
  Future<bool> submit({
    required Member member,
    required String taskId,
    String? note,
    List<PhotoCapture> photos = const [],
  }) async {
    final reportedAt = _clock();
    try {
      await _repository.submitTask(member: member, taskId: taskId, note: note, photos: photos);
      return true;
    } on AppException catch (e) {
      if (!_retryable.contains(e.code)) rethrow;
    }
    _items.add(
      PendingReport(
        id: '${reportedAt.microsecondsSinceEpoch}-${_seq++}',
        memberId: member.id,
        taskId: taskId,
        reportedAt: reportedAt,
        note: note,
        photos: photos,
      ),
    );
    await _store.save(_items);
    notifyListeners();
    return false;
  }

  /// Kirim antrean milik [member]. Mengembalikan jumlah yang terkirim.
  Future<int> flush(Member member) async {
    if (_flushing) return 0;
    _flushing = true;
    var sent = 0;
    try {
      for (final report in pendingFor(member.id)) {
        if (_clock().difference(report.reportedAt) > maxAge) {
          _remove(report, dropped: 'Laporan yang tersimpan lebih dari 24 jam tidak bisa dikirim lagi.');
          continue;
        }
        try {
          await _repository.submitTask(
            member: member,
            taskId: report.taskId,
            note: report.note,
            photos: report.photos,
            reportedAt: report.reportedAt,
          );
          _remove(report);
          sent++;
        } on AppException catch (e) {
          // Masih tanpa sinyal: coba lagi nanti, urutan laporan tetap dijaga
          if (_retryable.contains(e.code)) break;
          // Mis. tugas diarsipkan atau jatah sudah terpakai (laporan pertama ternyata sampai)
          _remove(report, dropped: 'Satu laporan tidak terkirim: ${e.message}');
        }
      }
    } finally {
      _flushing = false;
      await _store.save(_items);
      notifyListeners();
    }
    return sent;
  }

  void _remove(PendingReport report, {String? dropped}) {
    _items.remove(report);
    if (dropped != null) droppedMessage = dropped;
  }
}
