// ignore_for_file: lines_longer_than_80_chars
import 'strings.dart';

/// Teks Bahasa Indonesia. Tambah teks baru di [S], lalu di sini dan di file bahasa lainnya.
class SId extends S {
  const SId();

  @override
  String get languageCode => 'id';

  @override
  String get back => 'Kembali';

  @override
  String get continueLabel => 'Lanjut';

  @override
  String get saving => 'Menyimpan...';

  @override
  String get checking => 'Memeriksa...';

  @override
  String get preparing => 'Menyiapkan...';

  @override
  String get sending => 'Mengirim...';

  @override
  String get signOut => 'Keluar';

  @override
  String get done => 'Selesai';

  @override
  String get tasks => 'Tugas';

  @override
  String get rewards => 'Hadiah';

  @override
  String get welcomeTitle => 'Siapa yang pakai HP ini?';

  @override
  String get welcomeSubtitle => 'Orang tua mengatur tugas dan hadiah. Anak mengumpulkan poin.';

  @override
  String get welcomeParent => 'Saya orang tua';

  @override
  String get welcomeChild => 'Saya anak';

  @override
  String get demoModeNote => 'Mode demo: belum tersambung ke server, data hanya tersimpan selama app terbuka.';

  @override
  String get devComponents => 'Lihat komponen desain';

  @override
  String get joinCodeLength => 'Kode terdiri dari 6 huruf/angka.';

  @override
  String joinHello(String name) => 'Halo, $name!';

  @override
  String get pinSubtitle => 'Buat PIN 4 angka supaya profilmu aman kalau HP dipakai bergantian.';

  @override
  String get pinLabel => 'PIN';

  @override
  String get savePin => 'Simpan PIN';

  @override
  String get skipForNow => 'Lewati dulu';

  @override
  String get joinTitle => 'Gabung keluarga';

  @override
  String get joinSubtitleAdult => 'Masukkan kode undangan dari pemilik keluarga.';

  @override
  String get joinSubtitleChild => 'Minta orang tua membuka tab Keluarga di HP-nya, lalu masukkan kodenya di sini.';

  @override
  String get inviteCodeLabel => 'Kode undangan';

  @override
  String get nicknameLabel => 'Nama panggilanmu';

  @override
  String get nicknameHintAdult => 'mis. Ayah';

  @override
  String get joinButton => 'Gabung';

  @override
  String get onbNamesRequired => 'Isi nama keluarga dan nama panggilanmu dulu ya.';

  @override
  String get onbCreateTitle => 'Buat keluarga';

  @override
  String get onbCreateSubtitle => 'Mulai dari nama keluarga. Semua bisa diubah nanti.';

  @override
  String get familyNameLabel => 'Nama keluarga';

  @override
  String get familyNameHint => 'mis. Keluarga Rina';

  @override
  String get nicknameHintOwner => 'mis. Ibu Rina';

  @override
  String get onbHaveInvite => 'Punya kode undangan dari pasangan?';

  @override
  String get onbAddChildTitle => 'Tambah anak';

  @override
  String get onbAddChildSubtitle => 'Anak tidak perlu email atau nomor HP. Nanti cukup masukkan kode di HP-nya.';

  @override
  String get birthDateEmpty => 'Tanggal lahir belum diisi';

  @override
  String get addChild => 'Tambah anak';

  @override
  String get addAnotherChild => 'Tambah anak lagi';

  @override
  String get onbTemplateTitle => 'Pilih template poin';

  @override
  String get onbTemplateSubtitle =>
      'Isi otomatis contoh tugas dan hadiah sesuai usia. Angkanya bisa diubah kapan saja.';

  @override
  String templateSummary(String daily, String screen) => '±$daily poin/hari · 30 menit layar = $screen poin';

  @override
  String get suggested => 'Disarankan';

  @override
  String get useTemplate => 'Pakai template ini';

  @override
  String get skipTemplate => 'Lewati, isi sendiri nanti';

  @override
  String get onbReviewTitle => 'Cek tugas & hadiah';

  @override
  String get onbReviewSubtitle => 'Ini contoh dari template. Ubah atau hapus nanti di tab Tugas dan Hadiah.';

  @override
  String get rewardGoalSaved => 'Goal (ditabung)';

  @override
  String get rewardInstant => 'Instan';

  @override
  String get onbConnectTitle => 'Hubungkan HP anak';

  @override
  String get onbConnectSubtitle => 'Di HP anak: buka app, pilih "Saya anak", lalu masukkan kodenya.';

  @override
  String get onbConnectNote => 'Kode baru bisa dibuat kapan saja di tab Keluarga.';

  @override
  String get loginSubtitle => 'Masuk ke akun orang tua. Anak tidak perlu akun.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Kata sandi';

  @override
  String get signIn => 'Masuk';

  @override
  String get or => 'atau';

  @override
  String get continueGoogle => 'Lanjut dengan Google';

  @override
  String get continueApple => 'Lanjut dengan Apple';

  @override
  String get usePhone => 'Pakai nomor HP';

  @override
  String get noAccount => 'Belum punya akun?';

  @override
  String get createAccount => 'Daftar akun baru';

  @override
  String get otpTitle => 'Masukkan kode OTP';

  @override
  String otpSubtitle(String phone) => 'Kode 6 angka dikirim lewat SMS ke $phone.';

  @override
  String get phoneTitle => 'Nomor HP kamu';

  @override
  String get phoneSubtitle => 'Kami kirim kode OTP lewat SMS.';

  @override
  String get phoneLabel => 'Nomor HP';

  @override
  String get sendCode => 'Kirim kode';

  @override
  String get otpLabel => 'Kode OTP';

  @override
  String get resendCode => 'Kirim ulang kode';

  @override
  String demoOtp(String otp) => 'Mode demo: kode OTP selalu $otp.';

  @override
  String get registerTitle => 'Daftar akun';

  @override
  String get registerSubtitle => 'Buat akun orang tua untuk menyimpan data keluarga.';

  @override
  String get passwordHint => 'Minimal 6 karakter';

  @override
  String get repeatPassword => 'Ulangi kata sandi';

  @override
  String get registering => 'Mendaftarkan...';

  @override
  String get register => 'Daftar';

  @override
  String get confirmEmailSent => 'Akun dibuat. Buka tautan konfirmasi di email kamu, lalu kembali dan pilih Masuk.';

  @override
  String get registerGoogle => 'Daftar dengan Google';

  @override
  String get haveAccount => 'Sudah punya akun?';

  @override
  String get forgotPassword => 'Lupa kata sandi?';

  @override
  String get resetTitle => 'Atur ulang kata sandi';

  @override
  String get resetSubtitle => 'Masukkan email akunmu. Kami kirim kode untuk membuat kata sandi baru.';

  @override
  String get resetCodeTitle => 'Cek email kamu';

  @override
  String resetCodeSubtitle(String email) =>
      'Kalau $email terdaftar, kami kirim email berisi tautan. Buka email itu di HP ini, lalu ketuk tautannya. Cek juga folder spam.';

  @override
  String get haveResetCode => 'Emailnya berisi kode? Masukkan di sini';

  @override
  String get resendEmail => 'Kirim ulang email';

  @override
  String get demoOpenResetLink => 'Buka tautan dari email (demo)';

  @override
  String get newPasswordTitle => 'Buat kata sandi baru';

  @override
  String get newPasswordSubtitle => 'Kamu masuk lewat tautan dari email. Buat kata sandi baru untuk akun ini.';

  @override
  String get resetCodeLabel => 'Kode dari email';

  @override
  String get newPassword => 'Kata sandi baru';

  @override
  String get saveNewPassword => 'Simpan & masuk';

  @override
  String demoResetCode(String code) => 'Mode demo: kodenya selalu $code.';

  @override
  String get navHome => 'Beranda';

  @override
  String get navApprovals => 'Persetujuan';

  @override
  String get navFamily => 'Keluarga';

  @override
  String get navHistory => 'Riwayat';

  @override
  String helloName(String name) => 'Halo, $name';

  @override
  String get familySettingsLabel => 'Keluarga & pengaturan';

  @override
  String get familyCardDesc => 'Anggota, kode undangan, dan pengaturan';

  @override
  String get openFamily => 'Buka keluarga';

  @override
  String get pendingApprovalsTitle => 'Persetujuan menunggu';

  @override
  String get nothingWaiting => 'Tidak ada yang menunggu.';

  @override
  String taskReportsCount(int n) => '$n laporan tugas';

  @override
  String redemptionsCount(int n) => '$n penukaran hadiah';

  @override
  String get openApprovalQueue => 'Buka antrean persetujuan';

  @override
  String get noChildrenYet => 'Belum ada anak. Tambahkan di tab Keluarga.';

  @override
  String pointsAmount(String points) => '$points poin';

  @override
  String streakDays(int n) => 'streak $n hari';

  @override
  String goalPercent(int percent) => 'goal $percent%';

  @override
  String get notConnected => 'belum terhubung';

  @override
  String get settings => 'Pengaturan';

  @override
  String get todayTasks => 'Tugas hari ini';

  @override
  String get noTasksToday => 'Belum ada tugas hari ini.';

  @override
  String get allTasksDone => 'Semua tugas beres. Keren!';

  @override
  String tasksLeft(int n) => 'Tinggal $n tugas lagi, semangat!';

  @override
  String get signOutDeviceTitle => 'Keluar dari HP ini?';

  @override
  String get signOutChildNote => 'Poinmu tetap aman. Untuk masuk lagi, minta kode baru ke orang tua.';

  @override
  String get cancel => 'Batal';

  @override
  String get goal => 'Goal';

  @override
  String get newTask => 'Tugas baru';

  @override
  String get activeFilter => 'Aktif';

  @override
  String get archivedFilter => 'Arsip';

  @override
  String get allChildren => 'Semua anak';

  @override
  String get allFrequencies => 'Semua frekuensi';

  @override
  String get loadTasksFailed => 'Gagal memuat tugas.';

  @override
  String get noArchivedTasks => 'Tidak ada tugas di arsip.';

  @override
  String get noTasksYet => 'Belum ada tugas. Tekan + untuk membuat.';

  @override
  String get noMatchingTasks => 'Tidak ada tugas yang cocok.';

  @override
  String get noTasksForYou => 'Belum ada tugas untukmu. Tanya orang tua ya.';

  @override
  String get allTodayDone => 'Semua tugas hari ini beres. Keren!';

  @override
  String queuedReports(int n) => '$n laporan menunggu sinyal. Dikirim otomatis saat HP online lagi.';

  @override
  String get otherDays => 'Hari lain';

  @override
  String get tryToSend => 'Coba kirim';

  @override
  String get close => 'Tutup';

  @override
  String get waitingSignal => 'Menunggu sinyal';

  @override
  String get taskNotFound => 'Tugas tidak ditemukan';

  @override
  String get editTask => 'Ubah tugas';

  @override
  String get taskNameLabel => 'Nama tugas';

  @override
  String get taskNameHint => 'mis. Siram tanaman';

  @override
  String get iconLabel => 'Ikon';

  @override
  String get pointsLabel => 'Poin';

  @override
  String get pointsChangeHint => 'Mengubah poin tidak mengubah poin yang sudah pernah diberikan.';

  @override
  String get descriptionOptional => 'Deskripsi (opsional)';

  @override
  String get taskDescHint => 'mis. Semua pot di teras';

  @override
  String get howOften => 'Seberapa sering?';

  @override
  String get daysLabel => 'Hari';

  @override
  String get maxPerDay => 'Maks laporan per hari';

  @override
  String get maxPerDayHint => 'Mencegah tugas termudah diulang terus.';

  @override
  String get verificationLabel => 'Cara verifikasi';

  @override
  String get verifyAutoHint => 'Poin langsung masuk. Kamu bisa membatalkannya dalam 24 jam.';

  @override
  String get verifyApproveHint => 'Poin masuk setelah kamu menyetujui laporannya.';

  @override
  String get verifyPhotoHint => 'Anak wajib memotret hasilnya dari kamera di app.';

  @override
  String get minPhotos => 'Minimal foto';

  @override
  String get beforeAfterLabel => 'Foto sebelum & sesudah';

  @override
  String get beforeAfterDesc => 'Mis. kamar berantakan lalu rapi.';

  @override
  String get allowGalleryLabel => 'Boleh dari galeri';

  @override
  String get allowGalleryDesc =>
      'Mis. foto nilai ujian dari guru. Biasanya hanya kamera, supaya tidak pakai foto lama.';

  @override
  String get forWhom => 'Untuk siapa?';

  @override
  String get saveTask => 'Simpan tugas';

  @override
  String get reactivate => 'Aktifkan lagi';

  @override
  String get archiveAction => 'Arsipkan';

  @override
  String get archiveTaskHint => 'Tugas yang diarsipkan hilang dari daftar anak, tapi riwayatnya tetap ada.';

  @override
  String taskIconName(String key) => switch (key) {
    'bed' => 'kasur',
    'dish' => 'piring',
    'book' => 'buku',
    'pencil' => 'pensil',
    'broom' => 'sapu',
    'trophy' => 'piala',
    'tooth' => 'gigi',
    'dog' => 'hewan peliharaan',
    'plant' => 'tanaman',
    'basket' => 'keranjang',
    'shirt' => 'baju',
    'trash' => 'sampah',
    'bath' => 'mandi',
    'math' => 'kalkulator',
    'music' => 'musik',
    'run' => 'olahraga',
    _ => key,
  };

  @override
  String iconSemantic(String name) => 'Ikon $name';

  @override
  String pointsEarned(String points) => '+$points poin masuk!';

  @override
  String get newPhotoSent => 'Foto baru terkirim! Tunggu orang tua memeriksa ya.';

  @override
  String get reportSent => 'Laporan terkirim! Tunggu orang tua memeriksa ya.';

  @override
  String get ok => 'Oke';

  @override
  String get preparingPhoto => 'Menyiapkan foto...';

  @override
  String get cameraUnavailable => 'Kamera tidak bisa dibuka. Cek izin kamera di pengaturan HP.';

  @override
  String get uploadingPhoto => 'Mengunggah foto...';

  @override
  String get offlineQueued => 'Tidak ada sinyal. Laporan disimpan dan dikirim otomatis nanti.';

  @override
  String takenAt(String time) => 'Diambil $time';

  @override
  String retakeRequested(String reason) =>
      'Orang tua minta foto ulang: $reason. Laporanmu tetap jalan dan streak tidak putus.';

  @override
  String get photoUnclear => 'fotonya kurang jelas';

  @override
  String get reportAutoHint => 'Poinnya langsung masuk begitu kamu lapor.';

  @override
  String get reportApproveHint => 'Orang tua akan memeriksa dulu, lalu poinnya masuk.';

  @override
  String get reportBeforeAfterHint => 'Foto keadaan sebelum dan sesudah dikerjakan, lalu kirim ke orang tua.';

  @override
  String get reportPhotoHint => 'Foto hasil kerjamu, lalu kirim ke orang tua.';

  @override
  String get noteOptional => 'Catatan (opsional)';

  @override
  String get reportNoteHintPhoto => 'mis. Mejanya juga sudah dilap';

  @override
  String get reportNoteHint => 'mis. Piringnya sudah di rak';

  @override
  String get sendRetake => 'Kirim foto ulang';

  @override
  String get sendReport => 'Kirim laporan';

  @override
  String photoTapToView(String name) => 'Foto $name, ketuk untuk melihat';

  @override
  String get retakePhoto => 'Ambil ulang';

  @override
  String photoOf(String kind) => 'Foto $kind';

  @override
  String get takePhoto => 'Ambil foto';

  @override
  String get addPhoto => 'Tambah foto';

  @override
  String get fromGallery => 'Dari galeri';

  @override
  String get taskReports => 'Laporan tugas';

  @override
  String taskReportsWithCount(int n) => 'Laporan tugas ($n)';

  @override
  String get rewardRedemptions => 'Penukaran hadiah';

  @override
  String get loadReportsFailed => 'Gagal memuat laporan.';

  @override
  String get noPendingReports => 'Tidak ada laporan yang menunggu. Mantap!';

  @override
  String get waitingOver3Days => 'menunggu > 3 hari';

  @override
  String get noPendingRedemptions => 'Tidak ada penukaran yang menunggu.';

  @override
  String get redemptionRequested => 'minta tukar';

  @override
  String get redemptionApprovedNotGiven => 'disetujui, belum diberikan';

  @override
  String get reportNotFound => 'Laporan tidak ditemukan';

  @override
  String reportedAt(String time) => 'Dilaporkan $time';

  @override
  String noteFrom(String name) => 'Catatan $name';

  @override
  String get backToQueue => 'Kembali ke antrean';

  @override
  String get bonusOptional => 'Bonus (opsional)';

  @override
  String get noBonus => 'Tanpa bonus';

  @override
  String get approve => 'Setujui';

  @override
  String approveWithBonus(int bonus) => 'Setujui + bonus $bonus';

  @override
  String get askRetake => 'Minta foto ulang';

  @override
  String get reject => 'Tolak';

  @override
  String get reasonPhotoBlurry => 'Fotonya buram';

  @override
  String get reasonResultNotVisible => 'Hasilnya tidak kelihatan';

  @override
  String get reasonNotFinished => 'Belum selesai';

  @override
  String get reasonNotTidy => 'Kurang rapi';

  @override
  String get reasonNotAsAsked => 'Belum sesuai permintaan';

  @override
  String get rejectReportTitle => 'Tolak laporan';

  @override
  String get retakeExplain => 'Laporannya tetap jalan, anak cukup memotret ulang. Streak tidak putus.';

  @override
  String get rejectExplain => 'Anak akan melihat alasan ini dan bisa melapor ulang.';

  @override
  String get reasonLabel => 'Alasan';

  @override
  String get retakeNoteHint => 'mis. Lantainya belum kelihatan';

  @override
  String get rejectReasonHint => 'mis. Lantainya masih kotor';

  @override
  String get sendRejection => 'Kirim penolakan';

  @override
  String get photosLoadFailed => 'Foto tidak bisa dimuat.';

  @override
  String get noPhotos => 'Tidak ada foto.';

  @override
  String get fromGallerySuffix => ' · dari galeri';

  @override
  String proofPhotoSemantic(int index, int total) => 'Foto bukti $index dari $total, ketuk untuk memperbesar';

  @override
  String rejectReasonRequired(String name) => 'Tulis alasan menolak, $name akan melihatnya.';

  @override
  String redemptionSummary(String name, String points, String time) => '$name · $points poin · $time';

  @override
  String screenTimeManual(String name, int minutes) =>
      'Buka akses untuk $name secara manual (Screen Time / Family Link) selama $minutes menit. Timer sudah berjalan di HP-nya.';

  @override
  String screenTimeAfterApprove(int minutes, String name) =>
      'Setelah disetujui, timer $minutes menit berjalan di HP $name.';

  @override
  String get pointsHeld => 'Poin sudah ditahan. Kalau ditolak, poin kembali penuh.';

  @override
  String get rejectReasonRequiredLabel => 'Alasan (wajib bila menolak)';

  @override
  String get redemptionRejectHint => 'mis. Besok saja, sudah malam';

  @override
  String get markGivenHint => 'Sudah disetujui. Tandai bila hadiahnya sudah diberikan.';

  @override
  String get markGiven => 'Sudah diberikan';

  @override
  String get rejectReasonRequiredGeneric => 'Tulis alasannya supaya anak tahu apa yang perlu diperbaiki.';

  @override
  String get rewardShop => 'Toko hadiah';

  @override
  String get loadRewardsFailed => 'Gagal memuat hadiah.';

  @override
  String get inProgressRedemptions => 'Sedang ditukar';

  @override
  String get setAsideForGoal => 'Sisihkan poin untuk goal';

  @override
  String get instantRewards => 'Hadiah instan';

  @override
  String get goalRewards => 'Hadiah goal';

  @override
  String minutesAmount(int n) => '$n menit';

  @override
  String get enough => 'Cukup!';

  @override
  String shortBy(String points) => 'kurang $points';

  @override
  String get requestSent => 'Permintaan terkirim! Tunggu orang tua menyetujui ya.';

  @override
  String get screenTimeApproved => 'Disetujui! Timer sesimu sudah berjalan.';

  @override
  String get rewardYours => 'Hore! Hadiahnya untukmu.';

  @override
  String priceLabel(String points) => 'Harga: $points poin';

  @override
  String balanceAfter(String points) => 'Sisa poinmu setelah tukar: $points';

  @override
  String pointsShortMore(String points) => 'Poinmu kurang $points lagi.';

  @override
  String get parentWillApprove => 'Orang tua akan menyetujui dulu.';

  @override
  String get oneMoment => 'Sebentar...';

  @override
  String get redeemNow => 'Tukar sekarang';

  @override
  String shortPoints(String points) => 'Kurang $points poin';

  @override
  String get makeGoal => 'Jadikan goal';

  @override
  String waitingParentHeld(String points) => 'Menunggu orang tua · $points poin ditahan';

  @override
  String get approvedWaitGiven => 'Disetujui, tunggu diberikan';

  @override
  String get cancelAction => 'Batalkan';

  @override
  String timerSemantic(String title, int minutes) => '$title, sisa $minutes menit';

  @override
  String get fiveMinutesLeft => 'Sisa 5 menit lagi, siap-siap ya.';

  @override
  String untilTime(String time) => 'Sampai jam $time';

  @override
  String get setAsideTitle => 'Sisihkan untuk goal';

  @override
  String get setAsideNote => 'Poin yang disisihkan tidak terpakai untuk hadiah instan.';

  @override
  String allAmount(String points) => 'Semua ($points)';

  @override
  String get setAside => 'Sisihkan';

  @override
  String get priceRiseTitle => 'Harga naik 7 hari lagi';

  @override
  String priceRiseBody(String points) =>
      'Hadiah ini sedang ditabung anak sebagai goal. Supaya adil, harga baru $points poin berlaku 7 hari lagi dan anak diberi tahu.';

  @override
  String get rewardNotFound => 'Hadiah tidak ditemukan';

  @override
  String get newReward => 'Hadiah baru';

  @override
  String get editReward => 'Ubah hadiah';

  @override
  String get rewardNameLabel => 'Nama hadiah';

  @override
  String get rewardNameHint => 'mis. 30 menit main game';

  @override
  String get priceInPoints => 'Harga (poin)';

  @override
  String pendingPriceHint(String points, String date) => 'Kenaikan ke $points poin berlaku $date.';

  @override
  String get typeLabel => 'Jenis';

  @override
  String get instantTypeLabel => 'Instan (screen time & hal kecil)';

  @override
  String get instantTypeHint => 'Anak menukar kapan saja poinnya cukup, sesuai batas harian.';

  @override
  String get goalTypeHint => 'Anak menabung dan melihat progressnya sampai poinnya cukup.';

  @override
  String get screenTimeDuration => 'Durasi screen time (menit, opsional)';

  @override
  String get screenTimeDurationHint => 'Bila diisi, timer sesi berjalan di HP anak setelah disetujui.';

  @override
  String get maxPerDayShort => 'Maks per hari';

  @override
  String get noLimit => 'Tanpa batas';

  @override
  String get stockOptional => 'Stok (opsional)';

  @override
  String get stockHint => 'Kosongkan bila tanpa batas';

  @override
  String get needsParentApproval => 'Perlu persetujuan orang tua';

  @override
  String get saveReward => 'Simpan hadiah';

  @override
  String get noArchivedRewards => 'Tidak ada hadiah di arsip.';

  @override
  String get noRewardsYet => 'Belum ada hadiah. Tekan + untuk membuat.';

  @override
  String risesTo(String points, String date) => 'naik jadi $points mulai $date';

  @override
  String get openRewardShop => 'Buka toko hadiah';

  @override
  String get myGoal => 'Goal saya';

  @override
  String get noGoalYet => 'Belum ada goal. Pilih hadiah besar yang mau kamu tabung.';

  @override
  String get goalEnough => 'Poinmu cukup! Tukar sekarang.';

  @override
  String get collectPointsFirst => 'Kumpulkan poin dulu ya.';

  @override
  String daysLeftApprox(int n) => '±$n hari lagi';

  @override
  String get parentOrCaregiver => 'orang tua / pengasuh';

  @override
  String inviteChildHint(String name) => 'Di HP $name: buka app, pilih "Saya anak", lalu masukkan kode ini.';

  @override
  String get inviteAdultHint => 'Di HP mereka: masuk dengan akun sendiri, lalu pilih "Punya kode undangan?".';

  @override
  String get save => 'Simpan';

  @override
  String get loadMembersFailed => 'Gagal memuat anggota keluarga.';

  @override
  String get children => 'Anak';

  @override
  String get noChildren => 'Belum ada anak.';

  @override
  String get connectedToChildPhone => 'Terhubung ke HP anak';

  @override
  String get notConnectedToChildPhone => 'Belum terhubung ke HP anak';

  @override
  String get codeButton => 'Kode';

  @override
  String get parentsAndCaregivers => 'Orang tua & pengasuh';

  @override
  String get roleOwner => 'Pemilik';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get inviteAdult => 'Undang orang tua / pengasuh';

  @override
  String get familySettings => 'Pengaturan keluarga';

  @override
  String get quietStartHelp => 'Jam tidur mulai';

  @override
  String get quietEndHelp => 'Jam tidur selesai';

  @override
  String get timezoneLabel => 'Zona waktu';

  @override
  String get timezoneHint => 'Menentukan kapan tugas harian dan batas harian berganti hari.';

  @override
  String get languageLabel => 'Bahasa';

  @override
  String get languageHint => 'Berlaku untuk semua HP di keluarga ini.';

  @override
  String get quietHoursLabel => 'Jam tidur anak';

  @override
  String startsAt(String time) => 'Mulai $time';

  @override
  String endsAt(String time) => 'Selesai $time';

  @override
  String get quietHoursHint => 'Notifikasi untuk anak di jam ini ditahan dan dikirim setelah jam tidur selesai.';

  @override
  String get streakBonusLabel => 'Bonus streak 7 hari';

  @override
  String get none => 'Tidak ada';

  @override
  String get allowNegativeLabel => 'Penalti boleh melebihi saldo';

  @override
  String get allowNegativeHint => 'Saldo anak bisa jadi minus (utang poin).';

  @override
  String get birthDateHelp => 'Tanggal lahir';

  @override
  String get childNameRequired => 'Isi nama panggilan anak dulu ya.';

  @override
  String get childNameLabel => 'Nama panggilan anak';

  @override
  String get childNameHint => 'mis. Raka';

  @override
  String get avatarColor => 'Warna avatar';

  @override
  String get birthDateOptional => 'Tanggal lahir (opsional)';

  @override
  String get birthDateUse => 'Dipakai untuk menyarankan template poin sesuai usia.';

  @override
  String get pickDate => 'Pilih tanggal';

  @override
  String get penaltyBrokenPromise => 'Tidak menepati janji';

  @override
  String get penaltyOverTime => 'Main melebihi waktu';

  @override
  String get penaltyForgotTask => 'Lupa tugas penting';

  @override
  String get bonusHelped => 'Bantu tanpa disuruh';

  @override
  String get bonusGoodGrades => 'Nilai bagus';

  @override
  String get bonusGoodAttitude => 'Sikap baik hari ini';

  @override
  String get amountRequired => 'Isi jumlah poin dulu.';

  @override
  String adjustReasonRequired(String name) => 'Tulis alasannya. $name akan melihat alasan ini.';

  @override
  String penaltyExceedsBalance(String name, String points) => 'Penalti melebihi saldo $name ($points poin).';

  @override
  String penaltyFor(String name) => 'Penalti untuk $name';

  @override
  String bonusFor(String name) => 'Bonus untuk $name';

  @override
  String get pointsAmountLabel => 'Jumlah poin';

  @override
  String get penaltyReasonHint => 'mis. Main game lewat dari jatah';

  @override
  String get bonusReasonHint => 'mis. Bantu cuci mobil tanpa disuruh';

  @override
  String balanceBecomes(String name, String points) => 'Saldo $name jadi $points poin.';

  @override
  String get givePenalty => 'Beri penalti';

  @override
  String get giveBonus => 'Beri bonus';

  @override
  String get reverseReasonRequired => 'Tulis alasannya supaya anak tahu kenapa dibatalkan.';

  @override
  String reverseTitle(String task) => 'Batalkan "$task"?';

  @override
  String get reverseExplain =>
      'Poin tugas ini ditarik kembali. Kalau poinnya sudah terpakai, saldo bisa jadi minus (utang poin) dan lunas otomatis dari poin berikutnya.';

  @override
  String get reverseReasonHint => 'mis. Kasurnya belum dirapikan';

  @override
  String get reverseTask => 'Batalkan tugas';

  @override
  String get childNotFound => 'Anak tidak ditemukan';

  @override
  String get loadDataFailed => 'Gagal memuat data.';

  @override
  String get thisWeek => 'Minggu ini';

  @override
  String get tasksApproved => 'Tugas disetujui';

  @override
  String get pointsIn => 'Poin masuk';

  @override
  String get pointsOut => 'Poin keluar';

  @override
  String get bonus => 'Bonus';

  @override
  String get penalty => 'Penalti';

  @override
  String get pointsHistory => 'Riwayat poin';

  @override
  String get taskFallback => 'tugas';

  @override
  String get loadHistoryFailed => 'Gagal memuat riwayat.';

  @override
  String get statusWaitingParent => 'menunggu orang tua';

  @override
  String get statusApproved => 'disetujui';

  @override
  String get statusGiven => 'sudah diberikan';

  @override
  String statusRejected(String reason) => 'ditolak: $reason';

  @override
  String get statusCancelled => 'dibatalkan';

  @override
  String get pointTransactions => 'Transaksi poin';

  @override
  String get today => 'Hari ini';

  @override
  String get yesterday => 'Kemarin';

  @override
  String get noTransactions => 'Belum ada transaksi poin.';

  @override
  String get goalSavings => 'tabungan goal';

  @override
  String get tapToUndo => 'ketuk untuk membatalkan';

  @override
  String get freqOnce => 'Sekali';

  @override
  String get freqDaily => 'Harian';

  @override
  String get freqDaysOfWeek => 'Hari tertentu';

  @override
  String get freqWeekly => 'Mingguan';

  @override
  String get freqRepeat => 'Berulang';

  @override
  String get verifyAuto => 'Otomatis';

  @override
  String get verifyApprove => 'Persetujuan';

  @override
  String get verifyPhoto => 'Persetujuan + foto';

  @override
  String isoDayShort(int day) => const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][day - 1];

  @override
  String isoDayLong(int day) => const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'][day - 1];

  @override
  String monthShort(int month) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'][month - 1];

  @override
  String todayAt(String time) => 'Hari ini $time';

  @override
  String yesterdayAt(String time) => 'Kemarin $time';

  @override
  String get taskNameRequired => 'Isi nama tugas dulu.';

  @override
  String get taskNameTooLong => 'Nama tugas maksimal 60 karakter.';

  @override
  String get taskPointsRange => 'Poin harus antara 1 dan 100.000.';

  @override
  String get pickAtLeastOneDay => 'Pilih minimal satu hari.';

  @override
  String get dailyLimitRange => 'Batas per hari 1 sampai 20.';

  @override
  String get photoCountRange => 'Jumlah foto 1 sampai 3.';

  @override
  String get descriptionTooLong => 'Deskripsi maksimal 500 karakter.';

  @override
  String maxPerDayShortLabel(int n) => 'maks $n×/hari';

  @override
  String get rewardInstantShort => 'Instan';

  @override
  String get rewardNameRequired => 'Isi nama hadiah dulu.';

  @override
  String get rewardNameTooLong => 'Nama hadiah maksimal 60 karakter.';

  @override
  String get rewardCostRange => 'Harga harus antara 1 dan 10.000.000 poin.';

  @override
  String get durationRange => 'Durasi 1–1440 menit.';

  @override
  String get rewardDailyLimitMin => 'Batas per hari minimal 1.';

  @override
  String get stockNotNegative => 'Stok tidak boleh minus.';

  @override
  String stockAmount(int n) => 'stok $n';

  @override
  String get needsApprovalShort => 'perlu persetujuan';

  @override
  String get immediate => 'langsung';

  @override
  String get ledgerTask => 'Tugas';

  @override
  String ledgerBonus(String reason) => 'Bonus: $reason';

  @override
  String get greatWork => 'kerja bagus';

  @override
  String ledgerPenalty(String reason) => 'Penalti: $reason';

  @override
  String get ledgerStreak => 'Bonus streak';

  @override
  String ledgerRedeem(String reason) => 'Tukar: $reason';

  @override
  String get rewardFallback => 'hadiah';

  @override
  String ledgerRefund(String? reason) => reason == null ? 'Poin kembali' : 'Poin kembali: $reason';

  @override
  String ledgerReversal(String reason) => 'Dibatalkan: $reason';

  @override
  String get ledgerGoalSave => 'Ditabung untuk goal';

  @override
  String get ledgerGoalUnsave => 'Diambil dari tabungan goal';

  @override
  String get notScheduledToday => 'Bukan jadwal hari ini';

  @override
  String get notDoneYet => 'Belum dikerjakan';

  @override
  String get waitingApproval => 'Menunggu persetujuan';

  @override
  String get needsNewPhoto => 'Perlu foto ulang';

  @override
  String get rejectedTryAgain => 'Ditolak, coba lagi ya';

  @override
  String rejectedReasonTryAgain(String reason) => 'Ditolak: $reason. Coba lagi ya';

  @override
  String get undoneByParent => 'Dibatalkan orang tua';

  @override
  String approvedCanRepeat(int used, int limit) => 'Disetujui · bisa lagi ($used/$limit)';

  @override
  String get approvedLabel => 'Disetujui';

  @override
  String get photoBefore => 'Sebelum';

  @override
  String get photoAfter => 'Sesudah';

  @override
  String get needBeforeAfter => 'Butuh foto sebelum & sesudah';

  @override
  String get needBefore => 'Butuh foto sebelum';

  @override
  String get needAfter => 'Butuh foto sesudah';

  @override
  String needMorePhotos(int n) => 'Butuh $n foto lagi';

  @override
  String ageBandLabel(String range) => '$range tahun';

  @override
  String get familyNameRequired => 'Isi nama keluarga.';

  @override
  String get familyNameTooLong => 'Nama keluarga maksimal 60 karakter.';

  @override
  String get streakBonusRange => 'Bonus streak 0–100%.';

  @override
  String get reportExpired => 'Laporan yang tersimpan lebih dari 24 jam tidak bisa dikirim lagi.';

  @override
  String reportNotSent(String reason) => 'Satu laporan tidak terkirim: $reason';

  @override
  String get streakSuccess => 'berhasil';

  @override
  String get streakPending => 'menunggu persetujuan';

  @override
  String get streakEmpty => 'belum ada';

  @override
  String get streakToday => 'hari ini, belum ada laporan';

  @override
  String get daysInARow => ' hari berturut-turut';

  @override
  String get streakPendingNote => 'Menunggu persetujuan, streak aman dulu.';

  @override
  String get debtPaidAutomatically => 'Akan lunas otomatis dari poin berikutnya.';

  @override
  String inGoalSavings(String points) => '+ $points di tabungan goal';

  @override
  String beingRedeemed(String points) => '$points sedang ditukar';

  @override
  String debtSemantic(String points) => 'Utang poin $points';

  @override
  String balanceSemantic(String points) => 'Saldo $points poin';

  @override
  String get pointDebt => 'Utang poin';

  @override
  String get photoLoadFailed => 'Foto tidak bisa dimuat.';

  @override
  String proofPhotoOf(int index, int total) => 'Foto bukti $index dari $total';

  @override
  String get closePhoto => 'Tutup foto';

  @override
  String codeFor(String name) => 'Kode untuk $name';

  @override
  String codeSemantic(String spaced) => 'Kode $spaced';

  @override
  String get codeValidity => 'Berlaku 24 jam dan hanya bisa dipakai sekali.';

  @override
  String decrease(String label) => 'Kurangi $label';

  @override
  String increase(String label) => 'Tambah $label';

  @override
  String goalProgressSemantic(String title, String saved, String target, int percent) =>
      'Goal $title, $saved dari $target poin, $percent persen';

  @override
  String stepOf(int step, int total) => 'Langkah $step dari $total';

  @override
  String get emailHint => 'nama@email.com';

  @override
  String avatarSemantic(String color) => 'Avatar $color';

  @override
  String avatarColorName(String key) => switch (key) {
    'lime' => 'hijau',
    'lilac' => 'ungu',
    'sky' => 'biru',
    'peach' => 'oranye',
    'butter' => 'kuning',
    _ => key,
  };
}
