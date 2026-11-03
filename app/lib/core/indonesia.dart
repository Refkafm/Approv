/// Ubah nomor HP Indonesia ke format internasional untuk OTP: "0812-3456 7890" -> "+6281234567890".
/// Mengembalikan null bila tidak terlihat seperti nomor HP Indonesia.
String? normalizeIndonesianPhone(String input) {
  var digits = input.replaceAll(RegExp(r'[\s\-().]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
  if (digits.startsWith('8')) digits = '62$digits';
  if (!RegExp(r'^628\d{7,12}$').hasMatch(digits)) return null;
  return '+$digits';
}

/// Zona waktu keluarga dari offset HP: WIB, WITA, atau WIT. Default WIB.
String indonesianTimezoneFor(Duration offset) => switch (offset.inMinutes) {
  480 => 'Asia/Makassar',
  540 => 'Asia/Jayapura',
  _ => 'Asia/Jakarta',
};

/// Tanggal hari ini di zona waktu keluarga (families.timezone). Indonesia tidak memakai DST,
/// jadi cukup offset tetap; zona lain jatuh ke WIB.
DateTime familyToday(String timezone, {DateTime? now}) {
  final hours = switch (timezone) {
    'Asia/Makassar' => 8,
    'Asia/Jayapura' => 9,
    _ => 7,
  };
  final local = (now ?? DateTime.now()).toUtc().add(Duration(hours: hours));
  return DateTime(local.year, local.month, local.day);
}
