/// Error dari server/repository. [code] = pesan exception dari RPC
/// (lihat konvensi di supabase/migrations/20261102000300_functions.sql).
class AppException implements Exception {
  const AppException(this.code, {this.detail});

  final String code;

  /// DETAIL dari RPC, mis. nama admin yang sudah memproses laporan ('already_reviewed').
  final String? detail;

  /// Pesan untuk ditampilkan ke pengguna.
  String get message {
    if (code == 'already_reviewed') {
      final who = detail?.trim() ?? '';
      return who.isEmpty ? 'Laporan ini sudah diproses.' : 'Laporan ini sudah diproses oleh $who.';
    }
    return _messages[code] ?? 'Ada yang tidak beres. Coba lagi ya.';
  }

  static const _messages = {
    'invalid_invite': 'Kode tidak berlaku atau sudah dipakai. Minta kode baru ke orang tua.',
    'account_required': 'Kode ini untuk orang tua atau pengasuh. Masuk dulu dengan Google atau email.',
    'already_admin': 'Kamu sudah menjadi admin di keluarga ini.',
    'not_authenticated': 'Sesi berakhir. Masuk lagi ya.',
    'not_authorized': 'Kamu tidak punya akses untuk ini.',
    'owner_only': 'Hanya pemilik keluarga yang bisa melakukan ini.',
    'member_not_found': 'Anggota tidak ditemukan.',
    'plan_limit_children': 'Paket gratis hanya untuk 1 anak.',
    'plan_limit_admins': 'Paket gratis maksimal 2 admin.',
    'plan_limit_tasks': 'Paket gratis maksimal 10 tugas aktif. Arsipkan tugas lain dulu.',
    'invalid_task': 'Isian tugas belum lengkap atau tidak valid.',
    'not_found': 'Data tidak ditemukan. Mungkin sudah dihapus.',
    'invalid_pin': 'PIN harus 4 angka.',
    'invalid_phone': 'Nomor HP belum benar. Contoh: 0812 3456 7890.',
    'invalid_otp': 'Kode OTP salah atau sudah kedaluwarsa.',
    'auth_failed': 'Gagal masuk. Coba lagi.',
    'invalid_email': 'Alamat email belum benar.',
    'weak_password': 'Kata sandi minimal 6 karakter.',
    'invalid_login': 'Email atau kata sandi salah.',
    'email_taken': 'Email ini sudah terdaftar. Pilih Masuk.',
    'email_not_confirmed': 'Email belum dikonfirmasi. Buka tautan yang kami kirim ke email kamu dulu.',
    // Laporan & persetujuan (RPC submit_task / review_submission)
    'task_limit_reached': 'Tugas ini sudah dilaporkan. Tunggu besok atau periode berikutnya ya.',
    'task_not_available': 'Tugas ini sudah tidak tersedia.',
    'task_not_assigned': 'Tugas ini bukan untukmu.',
    'task_not_today': 'Tugas ini bukan jadwal hari ini.',
    'photos_required': 'Tugas ini butuh foto hasil kerjamu.',
    'member_cannot_earn': 'Akun ini tidak mengumpulkan poin.',
    'cannot_review_own': 'Laporanmu sendiri harus disetujui admin lain.',
    'reason_required': 'Tulis alasannya supaya anak tahu apa yang perlu diperbaiki.',
    'retake_requires_photo': 'Minta foto ulang hanya untuk tugas berfoto.',
    'invalid_bonus': 'Bonus tidak valid.',
    // Dompet (P-03, aturan bisnis 3)
    'invalid_amount': 'Jumlah poin tidak valid.',
    'insufficient_points': 'Poinnya tidak cukup.',
    'not_reversible': 'Transaksi ini tidak bisa dibatalkan.',
    'reversal_window_passed': 'Sudah lewat 24 jam, tugas otomatis tidak bisa dibatalkan lagi.',
    // Hadiah & goal (H-01–H-06, G-01–G-03)
    'invalid_reward': 'Isian hadiah belum lengkap atau tidak valid.',
    'invalid_cost': 'Harga harus antara 1 dan 10.000.000 poin.',
    'plan_limit_rewards': 'Paket gratis maksimal 5 hadiah aktif. Arsipkan hadiah lain dulu.',
    'reward_not_available': 'Hadiah ini sudah tidak tersedia.',
    'out_of_stock': 'Stok hadiah ini sudah habis.',
    'reward_limit_reached': 'Hadiah ini sudah ditukar sebanyak batas hari ini.',
    'not_cancellable': 'Penukaran ini sudah diproses, tidak bisa dibatalkan.',
    'no_active_goal': 'Pilih goal dulu ya.',
    'invalid_settings': 'Pengaturan belum valid.',
    // Bukti foto (PF-01–PF-07)
    'offline': 'Tidak ada sinyal. Coba lagi sebentar ya.',
    'upload_failed': 'Foto gagal diunggah. Periksa sinyal, lalu coba kirim lagi.',
    'photo_not_uploaded': 'Foto belum terunggah. Coba kirim lagi.',
    'invalid_photo': 'Foto ini tidak bisa dipakai. Ambil langsung dari kamera ya.',
    'too_many_photos': 'Fotonya kebanyakan. Maksimal 6 foto.',
    'photos_not_allowed': 'Tugas ini tidak memakai foto.',
    'not_awaiting_retake': 'Laporan ini tidak sedang menunggu foto ulang.',
  };

  @override
  String toString() => 'AppException($code${detail == null ? '' : ', $detail'})';
}
