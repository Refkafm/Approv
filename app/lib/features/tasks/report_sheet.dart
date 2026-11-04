import 'package:flutter/material.dart';

import '../../core/analytics.dart';
import '../../core/format.dart';
import '../../core/photo_picker.dart';
import '../../core/photo_processing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/photo_viewer.dart';
import '../../core/widgets/polaroid.dart';
import '../../core/widgets/status_stamp.dart';
import '../../data/app_exception.dart';
import '../../data/photo_models.dart';
import '../../data/task_models.dart';
import '../../data/task_rules.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../shell/session.dart';
import '../../l10n/strings.dart';

/// Lapor tugas selesai (PRD L-01, L-02, layar A-4, Flow 3 langkah 1–2), termasuk bukti foto
/// (PF-01–PF-03, PF-06, PF-07) dan kirim foto ulang (PF-05). Setelah terkirim, menampilkan stempel
/// MENUNGGU (atau DISETUJUI untuk verifikasi otomatis).
Future<void> showReportSheet(BuildContext context, TodayTask item) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
    builder: (_) => _ReportSheet(item),
  );
  if (sent != true || !context.mounted) return;

  final auto = item.task.verification == TaskVerification.auto;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            StatusStamp(status: auto ? StampStatus.approved : StampStatus.pending, animate: true),
            const SizedBox(height: 24),
            Text(
              auto
                  ? context.s.pointsEarned(formatPoints(item.task.points))
                  : (item.needsRetake ? context.s.newPhotoSent : context.s.reportSent),
              textAlign: TextAlign.center,
              style: AppText.titleMd,
            ),
            const SizedBox(height: 20),
            AppButton(label: context.s.ok, onPressed: () => Navigator.of(dialogContext).pop()),
          ],
        ),
      ),
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet(this.item);

  final TodayTask item;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  /// Maksimal foto yang bisa diambil (PF-01: minimal foto 1–3).
  static const _maxPhotos = 3;

  final _note = TextEditingController();
  final _photos = <PhotoCapture>[];
  bool _busy = false;
  String? _busyLabel;
  String? _error;

  Task get _task => widget.item.task;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _take(PhotoKind kind, {bool fromGallery = false}) async {
    final session = SessionScope.read(context);
    final picker = PhotoPickerScope.of(context);
    setState(() {
      _busy = true;
      _busyLabel = context.s.preparingPhoto;
      _error = null;
    });
    try {
      final takenAt = DateTime.now();
      final bytes = await picker.take(
        fromGallery: fromGallery,
        stamp: proofStampText(takenAt, session.activeMember!.name, _task.title),
      );
      if (bytes != null && mounted) {
        setState(() {
          if (kind != PhotoKind.single) _photos.removeWhere((p) => p.kind == kind);
          _photos.add(
            PhotoCapture(
              bytes: bytes,
              kind: kind,
              origin: fromGallery ? PhotoOrigin.gallery : PhotoOrigin.camera,
              takenAt: takenAt,
            ),
          );
        });
      }
    } on Exception {
      if (mounted) setState(() => _error = context.s.cameraUnavailable);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = null;
        });
      }
    }
  }

  Future<void> _send() async {
    final session = SessionScope.read(context);
    final member = session.activeMember!;
    setState(() {
      _busy = true;
      _busyLabel = _photos.isEmpty ? context.s.sending : context.s.uploadingPhoto;
      _error = null;
    });
    try {
      var sent = true;
      if (widget.item.needsRetake) {
        await session.repository.resubmitPhotos(
          member: member,
          submissionId: widget.item.latest!.id!,
          photos: List.of(_photos),
        );
      } else {
        sent = await session.reports.submit(
          member: member,
          taskId: _task.id,
          note: _note.text,
          photos: List.of(_photos),
        );
        session.track(AnalyticsEvent.taskSubmitted, {
          'verification': _task.verification.name,
          'photos': _photos.length,
          'offline': !sent,
        });
        if (!sent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.offlineQueued)));
        }
      }
      session.markDataChanged();
      // false: masuk antrean offline, jadi dialog "terkirim" tidak ditampilkan
      if (mounted) Navigator.of(context).pop(sent);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = null;
        });
      }
    }
  }

  void _preview(PhotoCapture photo) {
    final index = _photos.indexOf(photo);
    showPhotoViewer(context, [
      for (final p in _photos)
        ViewerPhoto(
          image: Future.value(MemoryImage(p.bytes)),
          caption: context.s.takenAt(formatReportTime(p.takenAt).toLowerCase()),
          label: p.kind.label,
        ),
    ], initial: index);
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final retake = widget.item.needsRetake;
    final missing = task.needsPhoto
        ? missingPhotosLabel(photos: _photos, minPhotos: task.minPhotos, beforeAfter: task.beforeAfter)
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.screenX,
        24,
        AppSpace.screenX,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 48,
                  child: CircleBadge(color: AppColors.pastelPeach, icon: AppIcons.task(task.icon)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(task.title, style: AppText.titleLg)),
                Text('+${formatPoints(task.points)}', style: AppText.titleLg),
              ],
            ),
            if (task.description != null) ...[const SizedBox(height: 8), Text(task.description!, style: AppText.body)],
            const SizedBox(height: 12),
            Text(
              retake
                  ? context.s.retakeRequested(widget.item.latest?.reason ?? context.s.photoUnclear)
                  : switch (task.verification) {
                      TaskVerification.auto => context.s.reportAutoHint,
                      TaskVerification.approve => context.s.reportApproveHint,
                      TaskVerification.photo =>
                        task.beforeAfter ? context.s.reportBeforeAfterHint : context.s.reportPhotoHint,
                    },
              style: AppText.body.copyWith(color: AppColors.inkMuted),
            ),
            if (task.needsPhoto) ...[const SizedBox(height: 20), _photoArea(task)],
            const SizedBox(height: 20),
            if (!retake) ...[
              AppTextField(
                label: context.s.noteOptional,
                controller: _note,
                hint: task.needsPhoto ? context.s.reportNoteHintPhoto : context.s.reportNoteHint,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 500,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
            ],
            AppButton(
              label: _busyLabel ?? missing ?? (retake ? context.s.sendRetake : context.s.sendReport),
              onPressed: _busy || missing != null ? null : _send,
            ),
            FormError(_error),
          ],
        ),
      ),
    );
  }

  Widget _photoArea(Task task) {
    final slots = task.beforeAfter ? [PhotoKind.before, PhotoKind.after] : null;
    final canAddMore = slots == null && _photos.length < _maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final (i, photo) in _photos.indexed)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Polaroid(
                    image: MemoryImage(photo.bytes),
                    seed: i,
                    width: 120,
                    label: photo.kind.label,
                    semanticLabel: context.s.photoTapToView(photo.kind.label.isEmpty ? '${i + 1}' : photo.kind.label),
                    onTap: () => _preview(photo),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: context.s.retakePhoto,
                    variant: AppButtonVariant.secondary,
                    expand: false,
                    icon: AppIcons.arrowCounterClockwise,
                    onPressed: _busy ? null : () => setState(() => _photos.remove(photo)),
                  ),
                ],
              ),
          ],
        ),
        if (_photos.isNotEmpty) const SizedBox(height: 16),
        if (slots != null)
          for (final kind in slots)
            if (!_photos.any((p) => p.kind == kind)) ...[
              _captureButtons(task, kind, context.s.photoOf(kind.label.toLowerCase())),
              const SizedBox(height: 12),
            ],
        if (canAddMore)
          _captureButtons(task, PhotoKind.single, _photos.isEmpty ? context.s.takePhoto : context.s.addPhoto),
      ],
    );
  }

  Widget _captureButtons(Task task, PhotoKind kind, String label) {
    return Column(
      children: [
        AppButton(
          label: label,
          icon: AppIcons.camera,
          variant: AppButtonVariant.secondary,
          onPressed: _busy ? null : () => _take(kind),
        ),
        if (task.allowGallery) ...[
          const SizedBox(height: 8),
          AppButton(
            label: context.s.fromGallery,
            icon: AppIcons.images,
            variant: AppButtonVariant.secondary,
            onPressed: _busy ? null : () => _take(kind, fromGallery: true),
          ),
        ],
      ],
    );
  }
}
