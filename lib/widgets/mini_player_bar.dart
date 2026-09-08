import 'package:flutter/material.dart';
import '../services/player_controller.dart';
import '../theme/app_theme.dart';

/// Bottom navigation'ın hemen üstünde görünen, dokununca full-screen
/// player'ı açan mini oynatıcı çubuğu.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({
    super.key,
    required this.controller,
    required this.onTap,
  });

  final PlayerController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final librarySong = controller.current;
    final song = librarySong?.song;
    if (song == null) return const SizedBox.shrink();

    final progress = controller.duration.inMilliseconds == 0
        ? 0.0
        : controller.position.inMilliseconds /
            controller.duration.inMilliseconds;

    // DEĞİŞTİ: "Genre | Mood" alt yazısı eklendi -- referans
    // tasarımdaki gibi ("Pop | Enerjik" formatı).
    final subtitleParts = [
      if (librarySong!.genre.isNotEmpty) librarySong.genre,
      if (librarySong.mood.isNotEmpty) librarySong.mood,
    ];
    final subtitle = subtitleParts.isEmpty ? '—' : subtitleParts.join(' | ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 2,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.purple),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  ClipRRect(
                    // DEĞİŞTİ: görsel büyütüldü (40 -> 52).
                    borderRadius: BorderRadius.circular(12),
                    child: song.imageUrl.isNotEmpty
                        ? Image.network(
                            song.imageUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                              ),
                            ),
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: controller.togglePlayPause,
                    icon: Icon(
                      controller.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  // YENİ: kapatma butonu -- referans tasarımdaki "X".
                  IconButton(
                    onPressed: controller.close,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}