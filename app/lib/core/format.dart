/// Format angka poin gaya Indonesia: 3200 -> "3.200", -10 -> "-10".
String formatPoints(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// Tanggal singkat gaya Indonesia: "12 Mar 2015".
String formatDateShort(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

/// Waktu laporan relatif terhadap hari ini: "Hari ini 10.30", "Kemarin 18.05", "3 Nov 07.15".
String formatReportTime(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final hm = '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';
  final days = DateTime(
    current.year,
    current.month,
    current.day,
  ).difference(DateTime(time.year, time.month, time.day)).inDays;
  if (days == 0) return 'Hari ini $hm';
  if (days == 1) return 'Kemarin $hm';
  return '${time.day} ${_months[time.month - 1]} $hm';
}
