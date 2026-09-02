import 'package:flutter/material.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.controller});

  final PlayerController controller;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final song = controller.current?.song;
          if (song == null) {
            return const Center(
              child: Text(
                'No song playing',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          final progress = controller.duration.inMilliseconds == 0
              ? 0.0
              : controller.position.inMilliseconds /
                  controller.duration.inMilliseconds;

          return Container(
            decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Now Playing',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: song.imageUrl.isNotEmpty
                          ? Image.network(
                              song.imageUrl,
                              width: 280,
                              height: 280,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderArt(),
                            )
                          : _placeholderArt(),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      song.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'AI Generated',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        activeTrackColor: AppColors.pink,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: progress.clamp(0, 1),
                        onChanged: (value) {
                          final target = Duration(
                            milliseconds:
                                (controller.duration.inMilliseconds * value)
                                    .round(),
                          );
                          controller.seek(target);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(controller.position),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(controller.duration),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: controller.togglePlayPause,
                            icon: Icon(
                              controller.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ActionIcon(
                          icon: controller.current!.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: controller.current!.isFavorite
                              ? AppColors.pink
                              : AppColors.textSecondary,
                          onTap: () {},
                        ),
                        _ActionIcon(
                          icon: Icons.download_outlined,
                          color: AppColors.textSecondary,
                          onTap: () {},
                        ),
                        _ActionIcon(
                          icon: Icons.share_outlined,
                          color: AppColors.textSecondary,
                          onTap: () {},
                        ),
                        _ActionIcon(
                          icon: Icons.playlist_add,
                          color: AppColors.textSecondary,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 64),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 24),
    );
  }
}