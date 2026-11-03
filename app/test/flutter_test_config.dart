import 'dart:async';

import 'package:family_points/core/theme/typography.dart';

/// Dimuat otomatis oleh flutter_test sebelum semua tes: jangan unduh Google Fonts saat tes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppText.useGoogleFonts = false;
  await testMain();
}
