import '../l10n/strings.dart';

/// Format angka poin: 3200 -> "3.200" (Indonesia) / "3,200" (Inggris), -10 -> "-10".
String formatPoints(int value) {
  final separator = S.current.languageCode == 'en' ? ',' : '.';
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(separator);
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Tanggal singkat: "12 Mar 2015" (nama bulan sesuai bahasa aktif).
String formatDateShort(DateTime date) => '${date.day} ${S.current.monthShort(date.month)} ${date.year}';

/// Waktu laporan relatif terhadap hari ini: "Hari ini 10.30", "Kemarin 18.05", "3 Nov 07.15".
String formatReportTime(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final hm = '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';
  final days = DateTime(
    current.year,
    current.month,
    current.day,
  ).difference(DateTime(time.year, time.month, time.day)).inDays;
  if (days == 0) return S.current.todayAt(hm);
  if (days == 1) return S.current.yesterdayAt(hm);
  return '${time.day} ${S.current.monthShort(time.month)} $hm';
}
