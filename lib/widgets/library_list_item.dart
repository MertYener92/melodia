import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kütüphanedeki içerik türü -- etiketin rengini ve yazısını belirler.
enum LibraryItemKind { music, video, remix }

extension LibraryItemKindStyle on LibraryItemKind {
  Color get accent => switch (this) {
    LibraryItemKind.music => AppColors.pink,
    LibraryItemKind.video => AppColors.purple,
    LibraryItemKind.remix => AppColors.blue,
  };

  IconData get placeholderIcon => switch (this) {
    LibraryItemKind.music => Icons.music_note_rounded,
    LibraryItemKind.video => Icons.movie_creation_rounded,
    LibraryItemKind.remix => Icons.autorenew_rounded,
  };
}

/// Kütüphane listesinin tek satırı: küçük kare kapak, içerik adı, altında
/// tür etiketi + "tarih · tür" bilgisi ve sağda üç nokta menüsü. Kart,
/// çerçeve ya da büyük görsel yok -- yoğun, minimal bir liste satırı.
class LibraryListItem extends StatelessWidget {
  const LibraryListItem({
    super.key,
    required this.title,
    required this.kind,
    required this.kindLabel,
    required this.metadata,
    required this.onTap,
    this.imageUrl = '',
    this.onMore,
    this.isPlaying = false,
    this.isDimmed = false,
    this.padding = const EdgeInsets.fromLTRB(20, 7, 8, 7),
  });

  final String title;
  final LibraryItemKind kind;
  final String kindLabel;
  final String metadata;
  final String imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final bool isPlaying;

  /// Henüz hazır olmayan (ör. üretimi süren video) öğe -- soluk gösterilir.
  final bool isDimmed;

  final EdgeInsetsGeometry padding;

  static const double _thumbSize = 56;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Opacity(
            opacity: isDimmed ? 0.6 : 1,
            child: Row(
              children: [
                _Thumbnail(
                  imageUrl: imageUrl,
                  kind: kind,
                  isPlaying: isPlaying,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPlaying
                              ? AppColors.pink
                              : AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _KindTag(label: kindLabel, color: kind.accent),
                          if (metadata.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                metadata,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onMore != null)
                  IconButton(
                    onPressed: onMore,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.imageUrl,
    required this.kind,
    required this.isPlaying,
  });

  final String imageUrl;
  final LibraryItemKind kind;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    const size = LibraryListItem._thumbSize;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kind.accent.withValues(alpha: 0.55),
            AppColors.surfaceElevated,
          ],
        ),
      ),
      child: Center(
        child: Icon(kind.placeholderIcon, color: Colors.white, size: 22),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isEmpty)
              placeholder
            else
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
            if (kind == LibraryItemKind.video)
              const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            if (isPlaying)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KindTag extends StatelessWidget {
  const _KindTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }
}
