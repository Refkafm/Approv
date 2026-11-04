import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/member_avatar.dart';
import '../../core/widgets/photo_viewer.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/polaroid.dart';
import '../../core/widgets/status_stamp.dart';
import '../../data/app_exception.dart';
import '../../data/photo_models.dart';
import '../../data/submission_repository.dart';
import '../../data/task_models.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../shell/session.dart';
import '../../l10n/strings.dart';

/// Detail laporan (PRD layar O-5, L-03, L-04, L-06, PF-05): setujui (+ bonus), tolak dengan alasan,
/// atau minta foto ulang. Stempel muncul setelah aksi (design.md 8). Foto bukti tampil di minggu 5.
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.item});

  /// null bila data hilang (mis. app dipulihkan setelah ditutup sistem).
  final ReviewItem? item;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  static const _bonusOptions = [0, 10, 20, 50];

  int _bonus = 0;
  bool _busy = false;
  String? _error;
  StampStatus? _result;
  Future<List<ProofPhoto>>? _photos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final item = widget.item;
    if (_photos == null && item != null && item.verification == TaskVerification.photo) {
      _photos = SessionScope.read(context).repository.submissionPhotos(item.id);
    }
  }

  Future<void> _review(ReviewAction action, {String? reason}) async {
    final session = SessionScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.repository.reviewSubmission(
        widget.item!.id,
        action,
        reason: reason,
        bonus: action == ReviewAction.approve ? _bonus : 0,
      );
      session.track(AnalyticsEvent.submissionReviewed, {
        'action': action.name,
        'minutes_to_review': DateTime.now().difference(widget.item!.createdAt).inMinutes,
      });
      session.markDataChanged();
      if (mounted) {
        setState(
          () => _result = switch (action) {
            ReviewAction.approve => StampStatus.approved,
            ReviewAction.reject => StampStatus.rejected,
            ReviewAction.retake => StampStatus.retake,
          },
        );
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askReason(ReviewAction action) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
      builder: (_) => _ReasonSheet(retake: action == ReviewAction.retake),
    );
    if (reason != null && mounted) await _review(action, reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item == null) {
      return OnboardingScaffold(title: context.s.reportNotFound, onBack: () => context.pop(), children: const []);
    }

    final result = _result;
    return OnboardingScaffold(
      title: item.taskTitle,
      onBack: _busy ? null : () => context.pop(),
      children: [
        Row(
          children: [
            MemberAvatar(name: item.memberName, avatarKey: item.memberAvatar, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.memberName, style: AppText.titleMd),
                  Text(
                    context.s.reportedAt(formatReportTime(item.createdAt).toLowerCase()),
                    style: AppText.bodySm.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            Text('+${formatPoints(item.points)}', style: AppText.titleLg),
          ],
        ),
        if (_photos != null) ...[const SizedBox(height: 24), _ProofPhotos(_photos!)],
        if (item.note != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: AppColors.ink, width: AppStroke.width),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.s.noteFrom(item.memberName), style: AppText.label),
                const SizedBox(height: 4),
                Text(item.note!, style: AppText.body),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        if (result != null) ...[
          Center(child: StatusStamp(status: result, animate: true)),
          const SizedBox(height: 32),
          AppButton(label: context.s.backToQueue, onPressed: () => context.pop()),
        ] else ...[
          Text(context.s.bonusOptional, style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in _bonusOptions)
                PillChip(
                  label: b == 0 ? context.s.noBonus : '+$b',
                  selected: _bonus == b,
                  onTap: _busy ? null : () => setState(() => _bonus = b),
                ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(
            label: _busy ? context.s.saving : (_bonus == 0 ? context.s.approve : context.s.approveWithBonus(_bonus)),
            onPressed: _busy ? null : () => _review(ReviewAction.approve),
          ),
          if (item.verification == TaskVerification.photo) ...[
            const SizedBox(height: 12),
            AppButton(
              label: context.s.askRetake,
              variant: AppButtonVariant.secondary,
              onPressed: _busy ? null : () => _askReason(ReviewAction.retake),
            ),
          ],
          const SizedBox(height: 12),
          AppButton(
            label: context.s.reject,
            variant: AppButtonVariant.destructive,
            onPressed: _busy ? null : () => _askReason(ReviewAction.reject),
          ),
          FormError(_error),
        ],
      ],
    );
  }
}

/// Alasan penolakan (wajib) atau catatan foto ulang (opsional), dengan pilihan cepat.
class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({required this.retake});

  final bool retake;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _reason = TextEditingController();
  String? _error;

  List<String> get _quick => widget.retake
      ? [context.s.reasonPhotoBlurry, context.s.reasonResultNotVisible]
      : [context.s.reasonNotFinished, context.s.reasonNotTidy, context.s.reasonNotAsAsked];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _reason.text.trim();
    if (!widget.retake && text.isEmpty) {
      setState(() => _error = context.s.rejectReasonRequiredGeneric);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
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
            Text(widget.retake ? context.s.askRetake : context.s.rejectReportTitle, style: AppText.titleLg),
            const SizedBox(height: 8),
            Text(
              widget.retake ? context.s.retakeExplain : context.s.rejectExplain,
              style: AppText.body.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in _quick)
                  PillChip(label: q, selected: _reason.text == q, onTap: () => setState(() => _reason.text = q)),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: widget.retake ? context.s.noteOptional : context.s.reasonLabel,
              controller: _reason,
              hint: widget.retake ? context.s.retakeNoteHint : context.s.rejectReasonHint,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 200,
              maxLines: 2,
              errorText: _error,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: widget.retake ? context.s.askRetake : context.s.sendRejection,
              variant: widget.retake ? AppButtonVariant.primary : AppButtonVariant.destructive,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto bukti sebagai polaroid; ketuk untuk layar penuh dengan zoom (PF-04).
class _ProofPhotos extends StatelessWidget {
  const _ProofPhotos(this.photos);

  final Future<List<ProofPhoto>> photos;

  @override
  Widget build(BuildContext context) {
    final repo = SessionScope.read(context).repository;
    return FutureBuilder<List<ProofPhoto>>(
      future: photos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(context.s.photosLoadFailed, style: AppText.body.copyWith(color: AppColors.tangerineDeep));
        }
        final list = snapshot.data ?? const <ProofPhoto>[];
        if (snapshot.connectionState == ConnectionState.done && list.isEmpty) {
          return Text(context.s.noPhotos, style: AppText.body.copyWith(color: AppColors.inkMuted));
        }
        final images = [for (final p in list) repo.proofImage(p)];
        void open(int index) => showPhotoViewer(context, [
          for (final (i, p) in list.indexed)
            ViewerPhoto(
              image: images[i],
              caption:
                  context.s.takenAt(formatReportTime(p.takenAt).toLowerCase()) +
                  (p.origin == PhotoOrigin.gallery ? context.s.fromGallerySuffix : ''),
              label: p.kind.label,
            ),
        ], initial: index);

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final (i, p) in list.indexed)
              FutureBuilder<ImageProvider>(
                future: images[i],
                builder: (context, image) => Polaroid(
                  image: image.data,
                  seed: i,
                  label: p.kind.label,
                  caption: formatReportTime(p.takenAt),
                  semanticLabel: context.s.proofPhotoSemantic(i + 1, list.length),
                  onTap: () => open(i),
                ),
              ),
          ],
        );
      },
    );
  }
}
