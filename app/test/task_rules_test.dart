import 'package:family_points/core/indonesia.dart';
import 'package:family_points/data/task_models.dart';
import 'package:family_points/data/task_rules.dart';
import 'package:flutter_test/flutter_test.dart';

// Kamis, 5 November 2026 (minggu ISO dimulai Senin 2 November)
final _thursday = DateTime(2026, 11, 5);

Task _task(
  String id, {
  TaskFrequency frequency = TaskFrequency.daily,
  int maxPerDay = 1,
  List<int> days = const [],
  List<String> assignees = const [],
  bool archived = false,
}) => Task(
  id: id,
  familyId: 'f',
  title: id,
  points: 10,
  frequency: frequency,
  verification: TaskVerification.approve,
  maxPerDay: maxPerDay,
  daysOfWeek: days,
  assigneeIds: assignees,
  isArchived: archived,
);

SubmissionSummary _sub(String taskId, SubmissionStatus status, DateTime day, {int minute = 0, bool reversed = false}) =>
    SubmissionSummary(
      taskId: taskId,
      status: status,
      forDate: day,
      createdAt: day.add(Duration(hours: 8, minutes: minute)),
      reversed: reversed,
    );

TodayTask _one(Task task, [List<SubmissionSummary> subs = const []]) =>
    buildTodayTasks(tasks: [task], submissions: subs, memberId: 'raka', today: _thursday).single;

void main() {
  group('buildTodayTasks (sama dengan cek RPC submit_task)', () {
    test('tugas harian tanpa laporan bisa dikerjakan', () {
      final t = _one(_task('kasur'));
      expect(t.canReport, isTrue);
      expect(t.statusLabel, 'Belum dikerjakan');
    });

    test('harian yang sudah disetujui hari ini selesai; kemarin tidak dihitung', () {
      final done = _one(_task('kasur'), [_sub('kasur', SubmissionStatus.approved, _thursday)]);
      expect(done.canReport, isFalse);
      expect(done.statusLabel, 'Disetujui');

      final yesterday = _one(_task('kasur'), [_sub('kasur', SubmissionStatus.approved, DateTime(2026, 11, 4))]);
      expect(yesterday.canReport, isTrue);
    });

    test('berulang maks 2×: setelah 1 laporan masih bisa lagi', () {
      final t = _one(_task('baca', frequency: TaskFrequency.repeat, maxPerDay: 2), [
        _sub('baca', SubmissionStatus.approved, _thursday),
      ]);
      expect(t.canReport, isTrue);
      expect(t.statusLabel, 'Disetujui · bisa lagi (1/2)');
    });

    test('laporan ditolak tidak menghabiskan jatah, anak bisa lapor ulang', () {
      final t = _one(_task('cuci'), [_sub('cuci', SubmissionStatus.rejected, _thursday)]);
      expect(t.canReport, isTrue);
      expect(t.statusLabel, 'Ditolak, coba lagi ya');
    });

    test('tugas otomatis yang dibatalkan tidak menghabiskan jatah', () {
      final t = _one(_task('kasur'), [_sub('kasur', SubmissionStatus.approved, _thursday, reversed: true)]);
      expect(t.canReport, isTrue);
      expect(t.statusLabel, 'Dibatalkan orang tua');
    });

    test('menunggu & perlu foto ulang menghabiskan jatah', () {
      expect(
        _one(_task('cuci'), [_sub('cuci', SubmissionStatus.pending, _thursday)]).statusLabel,
        'Menunggu persetujuan',
      );
      final retake = _one(_task('pr'), [_sub('pr', SubmissionStatus.needsRetake, _thursday)]);
      expect(retake.canReport, isFalse);
      expect(retake.statusLabel, 'Perlu foto ulang');
    });

    test('status mengikuti laporan terakhir', () {
      final t = _one(_task('cuci'), [
        _sub('cuci', SubmissionStatus.rejected, _thursday),
        _sub('cuci', SubmissionStatus.pending, _thursday, minute: 30),
      ]);
      expect(t.statusLabel, 'Menunggu persetujuan');
    });

    test('hari tertentu: hanya pada hari yang dipilih', () {
      expect(_one(_task('siram', frequency: TaskFrequency.daysOfWeek, days: [4])).canReport, isTrue);
      final notToday = _one(_task('siram', frequency: TaskFrequency.daysOfWeek, days: [1, 3]));
      expect(notToday.canReport, isFalse);
      expect(notToday.statusLabel, 'Bukan jadwal hari ini');
    });

    test('mingguan: laporan Senin minggu ini terhitung, minggu lalu tidak', () {
      final weekly = _task('kamar', frequency: TaskFrequency.weekly);
      expect(_one(weekly, [_sub('kamar', SubmissionStatus.approved, DateTime(2026, 11, 2))]).canReport, isFalse);
      expect(_one(weekly, [_sub('kamar', SubmissionStatus.approved, DateTime(2026, 11, 1))]).canReport, isTrue);
    });

    test('sekali: selesai selamanya setelah ada laporan yang tidak ditolak', () {
      final once = _task('ujian', frequency: TaskFrequency.once);
      expect(_one(once, [_sub('ujian', SubmissionStatus.approved, DateTime(2026, 9, 1))]).canReport, isFalse);
      expect(_one(once, [_sub('ujian', SubmissionStatus.rejected, DateTime(2026, 9, 1))]).canReport, isTrue);
    });

    test('hanya tugas aktif yang ditugaskan ke anak ini (kosong = semua anak)', () {
      final list = buildTodayTasks(
        tasks: [
          _task('semua'),
          _task('raka', assignees: ['raka']),
          _task('kiara', assignees: ['kiara']),
          _task('arsip', archived: true),
        ],
        submissions: const [],
        memberId: 'raka',
        today: _thursday,
      );
      expect(list.map((t) => t.task.id), unorderedEquals(['semua', 'raka']));
    });

    test('urutan: perlu foto ulang, bisa dikerjakan, menunggu, selesai, hari lain', () {
      final list = buildTodayTasks(
        tasks: [
          _task('selesai'),
          _task('lain', frequency: TaskFrequency.daysOfWeek, days: [1]),
          _task('menunggu'),
          _task('bisa'),
          _task('fotoulang'),
        ],
        submissions: [
          _sub('selesai', SubmissionStatus.approved, _thursday),
          _sub('menunggu', SubmissionStatus.pending, _thursday),
          _sub('fotoulang', SubmissionStatus.needsRetake, _thursday),
        ],
        memberId: 'raka',
        today: _thursday,
      );
      expect(list.map((t) => t.task.id), ['fotoulang', 'bisa', 'menunggu', 'selesai', 'lain']);
    });
  });

  group('TaskInput', () {
    const valid = TaskInput(
      title: 'Siram tanaman',
      points: 30,
      frequency: TaskFrequency.daily,
      verification: TaskVerification.approve,
    );

    test('validasi sama dengan CHECK tabel tasks', () {
      expect(valid.validate(), isNull);
      expect(
        const TaskInput(
          title: ' ',
          points: 30,
          frequency: TaskFrequency.daily,
          verification: TaskVerification.auto,
        ).validate(),
        'Isi nama tugas dulu.',
      );
      expect(
        const TaskInput(
          title: 'x',
          points: 0,
          frequency: TaskFrequency.daily,
          verification: TaskVerification.auto,
        ).validate(),
        'Poin harus antara 1 dan 100.000.',
      );
      expect(
        const TaskInput(
          title: 'x',
          points: 5,
          frequency: TaskFrequency.daysOfWeek,
          verification: TaskVerification.auto,
        ).validate(),
        'Pilih minimal satu hari.',
      );
    });

    test('toRow membersihkan opsi yang tidak berlaku', () {
      const input = TaskInput(
        title: '  Bersihkan kamar ',
        points: 150,
        frequency: TaskFrequency.weekly,
        maxPerDay: 5,
        daysOfWeek: [3, 1],
        verification: TaskVerification.approve,
        minPhotos: 3,
        beforeAfter: true,
        allowGallery: true,
        description: '  ',
      );
      final row = input.toRow();
      expect(row['title'], 'Bersihkan kamar');
      expect(row['max_per_day'], 1);
      expect(row['days_of_week'], isNull);
      expect(row['min_photos'], 0);
      expect(row['before_after'], isFalse);
      expect(row['allow_gallery'], isFalse);
      expect(row['description'], isNull);
    });

    test('Task.fromRow membaca penugasan', () {
      final task = Task.fromRow({
        'id': 't1',
        'family_id': 'f',
        'title': 'Siram',
        'icon': 'plant',
        'points': 30,
        'frequency': 'days_of_week',
        'days_of_week': [1, 3],
        'max_per_day': 1,
        'verification': 'photo',
        'min_photos': 2,
        'before_after': true,
        'allow_gallery': false,
        'is_archived': false,
        'task_assignments': [
          {'member_id': 'raka'},
        ],
      });
      expect(task.scheduleLabel, 'Sen, Rab · Persetujuan + foto');
      expect(task.assigneeIds, ['raka']);
      expect(task.isFor('raka'), isTrue);
      expect(task.isFor('kiara'), isFalse);
    });
  });

  test('familyToday memakai zona waktu keluarga', () {
    final utc = DateTime.utc(2026, 11, 2, 16, 30); // 23:30 WIB, 00:30 WITA
    expect(familyToday('Asia/Jakarta', now: utc), DateTime(2026, 11, 2));
    expect(familyToday('Asia/Makassar', now: utc), DateTime(2026, 11, 3));
    expect(familyToday('Asia/Jayapura', now: utc), DateTime(2026, 11, 3));
  });
}
