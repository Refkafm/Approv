import 'dart:async';

import 'package:flutter/widgets.dart';

import 'session.dart';

/// Muat ulang layar saat data keluarga berubah: dari layar lain di HP ini
/// ([SessionController.dataRevision]) atau dari HP lain lewat realtime (watchFamily di repository).
/// Juga saat app kembali ke depan, karena event realtime selama app di latar belakang bisa terlewat.
///
/// Panggil [listenForChanges] di didChangeDependencies dan isi [reload].
mixin ReloadOnChanges<T extends StatefulWidget> on State<T> {
  StreamSubscription<void>? _changesSub;
  ValueNotifier<int>? _revision;
  AppLifecycleListener? _lifecycle;

  void reload();

  void listenForChanges() {
    final session = SessionScope.read(context);
    _revision ??= session.dataRevision..addListener(_onChange);
    _lifecycle ??= AppLifecycleListener(onResume: _onChange);
    final familyId = session.activeMember?.familyId;
    if (_changesSub == null && familyId != null) {
      _changesSub = session.repository.watchFamily(familyId).listen((_) => _onChange());
    }
  }

  void _onChange() {
    if (mounted) reload();
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    _lifecycle?.dispose();
    _revision?.removeListener(_onChange);
    super.dispose();
  }
}
