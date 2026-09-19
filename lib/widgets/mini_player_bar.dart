import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';

import '../services/player_controller.dart';
import '../theme/app_theme.dart';
import 'player/player_shared.dart';

/// Bottom navigation'ın hemen üstünde, listenin üzerinde duran kompakt
/// oynatıcı. Tam ekran player'ın "küçültülmüş hali": aynı kapak (Hero),
/// aynı başlık/alt başlık ve aynı ikon ailesi.
///
/// Etkileşimler:
///  - Dokun / yukarı kaydır -> tam ekran player.
///  - Sola ya da aşağı kaydır -> çalmayı durdurup mini player'ı kapat
///    (eski "X" butonunun yerini alan kapatma davranışı).
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({
    super.key,
    required this.controller,
    required this.onTap,
  });

  final PlayerController controller;
  final VoidCallback onTap;

  static const double _height = 60;
  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final librarySong = controller.current;
    if (librarySong == null) return const SizedBox.shrink();
    final song = librarySong.song;
    final l10n = AppLocalizations.of(context)!;

    final totalMs = controller.duration.inMilliseconds;
    final progress = totalMs == 0
        ? 0.0
        : (controller.position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    final error = controller.error;
    final repeatActive = controller.repeatMode != PlayerRepeatMode.off;

    // YENİ: sola kaydırınca kart ekrandan kayarak çıkar ve çalma durur.
    return Dismissible(
      key: ValueKey('mini-player-${librarySong.song.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.close(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: GestureDetector(
          onTap: onTap,
          onVerticalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -250) onTap();
            if (v > 250) controller.close();
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: _height,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1826).withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 7, 4, 7),
                        child: Row(
                          children: [
                            SongArtwork(
                              imageUrl: song.imageUrl,
                              size: 46,
                              radius: 8,
                              heroTag: kPlayerArtworkHeroTag,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    error ?? playerSubtitle(librarySong, l10n),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: error != null
                                          ? AppColors.pink
                                          : AppColors.textSecondary,
                                      fontSize: 12.5,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: controller.cycleRepeatMode,
                              tooltip: l10n.playerRepeat,
                              iconSize: 22,
                              color: repeatActive
                                  ? AppColors.pink
                                  : AppColors.textSecondary,
                              icon: Icon(
                                controller.repeatMode == PlayerRepeatMode.one
                                    ? PlayerIcons.repeatOne
                                    : PlayerIcons.repeat,
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: controller.isLoading
                                  ? const Center(
                                      child: SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: controller.togglePlayPause,
                                      tooltip: controller.isPlaying
                                          ? l10n.playerPause
                                          : l10n.playerPlay,
                                      iconSize: 30,
                                      color: Colors.white,
                                      icon: Icon(
                                        controller.isPlaying
                                            ? PlayerIcons.pause
                                            : PlayerIcons.play,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      // Çok ince, dikkat dağıtmayan ilerleme çizgisi.
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 2,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.pink.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
