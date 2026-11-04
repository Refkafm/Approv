import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'icon_circle_button.dart';
import '../../l10n/strings.dart';

class ViewerPhoto {
  const ViewerPhoto({required this.image, required this.caption, this.label});

  final Future<ImageProvider> image;
  final String caption;

  /// "Sebelum" / "Sesudah"
  final String? label;
}

/// Foto layar penuh (PRD PF-04, design.md 7.8): latar ink, foto tegak, bisa di-zoom & digeser antar foto.
Future<void> showPhotoViewer(BuildContext context, List<ViewerPhoto> photos, {int initial = 0}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _PhotoViewer(photos: photos, initial: initial),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.initial});

  final List<ViewerPhoto> photos;
  final int initial;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => FutureBuilder<ImageProvider>(
                future: widget.photos[i].image,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(context.s.photoLoadFailed, style: AppText.body.copyWith(color: AppColors.surface)),
                    );
                  }
                  final image = snapshot.data;
                  if (image == null) return const SizedBox.expand();
                  return InteractiveViewer(
                    maxScale: 5,
                    child: Center(
                      child: Image(
                        image: image,
                        fit: BoxFit.contain,
                        semanticLabel: context.s.proofPhotoOf(i + 1, widget.photos.length),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: AppSpace.screenX,
              right: AppSpace.screenX,
              top: 8,
              child: Row(
                children: [
                  IconCircleButton(
                    icon: AppIcons.x,
                    semanticLabel: context.s.closePhoto,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (photo.label != null && photo.label!.isNotEmpty) ...[
                    _Pill(photo.label!),
                    const SizedBox(width: 8),
                  ],
                  if (widget.photos.length > 1) _Pill('${_index + 1}/${widget.photos.length}'),
                ],
              ),
            ),
            Positioned(
              left: AppSpace.screenX,
              right: AppSpace.screenX,
              bottom: 16,
              child: Text(
                photo.caption,
                textAlign: TextAlign.center,
                style: AppText.bodySm.copyWith(color: AppColors.surface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill)),
    child: Text(text, style: AppText.label),
  );
}
