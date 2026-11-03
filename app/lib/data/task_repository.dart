import 'models.dart';
import 'task_models.dart';
import 'task_rules.dart';

/// Tugas (PRD modul 3). Semua method melempar AppException saat gagal.
abstract interface class TaskRepository {
  /// Tugas keluarga beserta penugasannya, urut sesuai waktu dibuat.
  Future<List<Task>> listTasks(String familyId, {bool archived = false});

  Future<Task> createTask(String familyId, TaskInput input);

  /// Poin yang sudah pernah diberikan tidak berubah (dikunci di task_submissions.points_snapshot).
  Future<Task> updateTask(String taskId, TaskInput input);

  /// T-08: arsip tanpa menghapus riwayat.
  Future<void> setTaskArchived(String taskId, {required bool archived});

  /// Tugas untuk [member] hari ini (zona waktu keluarga) dengan status laporannya.
  Future<List<TodayTask>> todayTasks(Member member);
}
