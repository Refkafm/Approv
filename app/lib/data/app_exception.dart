import '../l10n/strings.dart';

/// Error dari server/repository. [code] = pesan exception dari RPC
/// (lihat konvensi di supabase/migrations/20261102000300_functions.sql).
class AppException implements Exception {
  const AppException(this.code, {this.detail});

  final String code;

  /// DETAIL dari RPC, mis. nama admin yang sudah memproses laporan ('already_reviewed').
  final String? detail;

  /// Pesan untuk ditampilkan ke pengguna.
  /// Pesan untuk ditampilkan ke pengguna, dalam bahasa aktif ([S.current]).
  String get message {
    final en = S.current.languageCode == 'en';
    if (code == 'already_reviewed') {
      final who = detail?.trim() ?? '';
      if (en) return who.isEmpty ? 'This report has already been handled.' : 'This report was already handled by $who.';
      return who.isEmpty ? 'Laporan ini sudah diproses.' : 'Laporan ini sudah diproses oleh $who.';
    }
    final text = (en ? _messagesEn : _messages)[code];
    // Login gagal: sertakan penyebab teknis (mis. dari Google/Supabase) agar bisa dilacak
    if (code == 'auth_failed' && detail != null && detail!.isNotEmpty) return '$text\n($detail)';
    return text ?? (en ? 'Something went wrong. Please try again.' : 'Ada yang tidak beres. Coba lagi ya.');
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
    'invalid_otp': 'Kodenya salah atau sudah kedaluwarsa.',
    'rate_limited': 'Terlalu sering mencoba. Tunggu beberapa menit, lalu coba lagi.',
    'identity_taken': 'Akun Google ini sudah dipakai akun lain di aplikasi, jadi tidak bisa dihubungkan.',
    'auth_failed': 'Gagal masuk. Coba lagi.',
    'invalid_email': 'Alamat email belum benar.',
    'weak_password': 'Kata sandi minimal 6 karakter.',
    'password_mismatch': 'Kata sandi yang diulang tidak sama.',
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

  static const _messagesEn = {
    'invalid_invite': 'This code is invalid or already used. Ask a parent for a new code.',
    'account_required': 'This code is for parents or caregivers. Sign in with Google or email first.',
    'already_admin': 'You are already an admin in this family.',
    'not_authenticated': 'Your session has ended. Please sign in again.',
    'not_authorized': "You don't have access to this.",
    'owner_only': 'Only the family owner can do this.',
    'member_not_found': 'Member not found.',
    'plan_limit_children': 'The free plan is for 1 kid only.',
    'plan_limit_admins': 'The free plan allows up to 2 admins.',
    'plan_limit_tasks': 'The free plan allows up to 10 active tasks. Archive another task first.',
    'invalid_task': 'The task details are incomplete or invalid.',
    'not_found': 'Not found. It may have been deleted.',
    'invalid_pin': 'The PIN must be 4 digits.',
    'invalid_phone': 'That phone number looks wrong. Example: 0812 3456 7890.',
    'invalid_otp': 'The code is wrong or has expired.',
    'rate_limited': 'Too many attempts. Wait a few minutes and try again.',
    'identity_taken': 'This Google account is already used by another account in the app, so it cannot be linked.',
    'auth_failed': 'Sign-in failed. Please try again.',
    'invalid_email': "That email address doesn't look right.",
    'weak_password': 'The password must be at least 6 characters.',
    'password_mismatch': "The passwords don't match.",
    'invalid_login': 'Wrong email or password.',
    'email_taken': 'This email is already registered. Choose Sign in.',
    'email_not_confirmed': 'Your email is not confirmed yet. Open the link we sent to your email first.',
    'task_limit_reached': 'This task has already been reported. Wait until tomorrow or the next period.',
    'task_not_available': 'This task is no longer available.',
    'task_not_assigned': "This task isn't for you.",
    'task_not_today': "This task isn't scheduled today.",
    'photos_required': 'This task needs a photo of your work.',
    'member_cannot_earn': "This account doesn't collect points.",
    'cannot_review_own': 'Your own report must be approved by another admin.',
    'reason_required': 'Write a reason so your kid knows what to fix.',
    'retake_requires_photo': 'You can only ask for a new photo on photo tasks.',
    'invalid_bonus': 'Invalid bonus.',
    'invalid_amount': 'Invalid number of points.',
    'insufficient_points': 'Not enough points.',
    'not_reversible': "This transaction can't be undone.",
    'reversal_window_passed': "More than 24 hours have passed; automatic tasks can't be undone anymore.",
    'invalid_reward': 'The reward details are incomplete or invalid.',
    'invalid_cost': 'The price must be between 1 and 10,000,000 points.',
    'plan_limit_rewards': 'The free plan allows up to 5 active rewards. Archive another reward first.',
    'reward_not_available': 'This reward is no longer available.',
    'out_of_stock': 'This reward is out of stock.',
    'reward_limit_reached': "This reward has reached today's limit.",
    'not_cancellable': "This request has already been handled and can't be cancelled.",
    'no_active_goal': 'Pick a goal first.',
    'invalid_settings': 'The settings are not valid.',
    'offline': 'No signal. Please try again in a moment.',
    'upload_failed': 'The photo failed to upload. Check your signal, then try sending again.',
    'photo_not_uploaded': "The photo hasn't been uploaded yet. Try sending again.",
    'invalid_photo': "This photo can't be used. Take it straight from the camera.",
    'too_many_photos': 'Too many photos. Up to 6 photos.',
    'photos_not_allowed': "This task doesn't use photos.",
    'not_awaiting_retake': "This report isn't waiting for a new photo.",
  };

  @override
  String toString() => 'AppException($code${detail == null ? '' : ', $detail'})';
}
