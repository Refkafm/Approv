import 'models.dart';

/// Akses data akun & keluarga. Semua method melempar [AppException] saat gagal.
/// Implementasi: SupabaseRepository (produksi) dan FakeRepository (tes & mode demo).
abstract interface class FamilyRepository {
  /// Berbunyi setiap kali status login berubah.
  Stream<void> get authChanges;

  Future<AuthUser?> currentUser();

  Future<void> signInWithGoogle();
  Future<void> signInWithApple();

  /// Masuk dengan email & kata sandi yang sudah terdaftar.
  Future<void> signInWithEmail(String email, String password);

  /// Mendaftarkan akun email. `false` jika server meminta konfirmasi email dulu (belum ada sesi).
  Future<bool> signUpWithEmail(String email, String password);

  /// [phone] dalam format internasional, mis. +6281234567890.
  Future<void> sendPhoneOtp(String phone);
  Future<void> verifyPhoneOtp(String phone, String code);

  /// Sesi tanpa email/nomor HP untuk HP anak.
  Future<void> signInAnonymously();
  Future<void> signOut();

  /// Anggota keluarga yang tertaut ke login ini.
  Future<List<Member>> myMemberships();

  /// Mengembalikan id keluarga baru. Pemanggil menjadi owner.
  Future<String> createFamily({required String familyName, required String ownerName});

  Future<Member> addChild({required String familyId, required String name, String? avatar, DateTime? birthDate});

  Future<void> applyTemplate({required String familyId, required AgeBand band});

  /// Anggota aktif keluarga, urut sesuai waktu dibuat.
  Future<List<Member>> familyMembers(String familyId);

  /// Kode 6 karakter, berlaku 24 jam, sekali pakai. [memberId] wajib untuk undangan anak.
  Future<String> createInvite({required String familyId, required MemberRole role, String? memberId});

  Future<Member> joinFamily({required String code, String? name});

  Future<void> setPin({required String memberId, required String pin});
}
