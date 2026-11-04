import 'dart:io';

/// Bahasa terakhir dipakai di HP ini ('id' / 'en'). Dipakai sebelum login dan saat app baru dibuka,
/// sebelum pengaturan keluarga selesai dimuat.
abstract interface class LanguageStore {
  Future<String?> load();
  Future<void> save(String code);
}

class MemoryLanguageStore implements LanguageStore {
  String? _code;

  @override
  Future<String?> load() async => _code;

  @override
  Future<void> save(String code) async => _code = code;
}

class FileLanguageStore implements LanguageStore {
  FileLanguageStore(this.file);

  final File file;

  @override
  Future<String?> load() async {
    try {
      final code = (await file.readAsString()).trim();
      return code == 'en' || code == 'id' ? code : null;
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> save(String code) async {
    try {
      await file.writeAsString(code, flush: true);
    } on FileSystemException {
      // Tidak fatal: bahasa tetap berlaku selama app terbuka
    }
  }
}
