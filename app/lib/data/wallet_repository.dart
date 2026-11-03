import 'models.dart';
import 'wallet_models.dart';

/// Dompet poin (PRD modul 5). Semua method melempar AppException saat gagal.
abstract interface class WalletRepository {
  /// Saldo, streak, dan aktivitas minggu ini (P-01, X-01).
  Future<WalletSummary> wallet(Member member);

  /// Riwayat transaksi terbaru di atas (P-02).
  Future<List<LedgerEntry>> history(String memberId, {int limit = 100});

  /// Bonus (+) atau penalti (−) manual dengan alasan wajib (P-03). Penalti tidak boleh membuat
  /// saldo negatif kecuali keluarga mengizinkan.
  Future<void> adjustPoints({required String memberId, required int amount, required String reason});

  /// Tugas verifikasi otomatis yang masih bisa dibatalkan (≤ 24 jam, aturan bisnis 3): id laporannya.
  Future<Set<String>> reversibleSubmissions(String memberId);

  /// Batalkan tugas otomatis; saldo boleh menjadi negatif ("utang poin").
  Future<void> reverseAutoTask({required String submissionId, required String reason});
}
