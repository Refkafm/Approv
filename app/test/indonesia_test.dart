import 'package:family_points/core/format.dart';
import 'package:family_points/core/indonesia.dart';
import 'package:family_points/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeIndonesianPhone', () {
    test('menerima format umum', () {
      expect(normalizeIndonesianPhone('0812-3456-7890'), '+6281234567890');
      expect(normalizeIndonesianPhone('+62 812 3456 7890'), '+6281234567890');
      expect(normalizeIndonesianPhone('6281234567890'), '+6281234567890');
      expect(normalizeIndonesianPhone('81234567890'), '+6281234567890');
    });

    test('menolak yang bukan nomor HP', () {
      expect(normalizeIndonesianPhone('021 555 1234'), isNull);
      expect(normalizeIndonesianPhone('0812'), isNull);
      expect(normalizeIndonesianPhone('abc'), isNull);
    });
  });

  test('zona waktu keluarga dari offset HP', () {
    expect(indonesianTimezoneFor(const Duration(hours: 7)), 'Asia/Jakarta');
    expect(indonesianTimezoneFor(const Duration(hours: 8)), 'Asia/Makassar');
    expect(indonesianTimezoneFor(const Duration(hours: 9)), 'Asia/Jayapura');
    expect(indonesianTimezoneFor(const Duration(hours: 1)), 'Asia/Jakarta');
  });

  test('tanggal singkat', () {
    expect(formatDateShort(DateTime(2015, 3, 12)), '12 Mar 2015');
  });

  test('usia & template yang disarankan', () {
    final raka = Member(
      id: '1',
      familyId: 'f',
      role: MemberRole.member,
      name: 'Raka',
      birthDate: DateTime(2013, 11, 3),
    );
    expect(raka.ageOn(DateTime(2026, 11, 2)), 12);
    expect(raka.ageOn(DateTime(2026, 11, 3)), 13);
    expect(AgeBand.forAge(8), AgeBand.young);
    expect(AgeBand.forAge(13), AgeBand.middle);
    expect(AgeBand.forAge(14), AgeBand.teen);
  });
}
