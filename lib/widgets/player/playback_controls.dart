import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';

import '../../services/player_controller.dart';
import '../../theme/app_theme.dart';
import 'player_shared.dart';

/// Shuffle · Önceki · [Oynat/Duraklat] · Sonraki · Tekrar.
///
/// Hiyerarşi: merkezdeki gradyanlı oynat butonu en baskın; önceki/sonraki
/// beyaz ve orta boy; shuffle/repeat küçük ve ikincil (aktifken pembe +
/// altında küçük nokta).
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key, required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSkip = controller.canSkip;
    final repeatMode = controller.repeatMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ToggleIcon(
          icon: PlayerIcons.shuffle,
          active: controller.shuffle,
          tooltip: l10n.playerShuffle,
          onTap: controller.toggleShuffle,
        ),
        _TransportIcon(
          icon: PlayerIcons.previous,
          tooltip: l10n.playerPrevious,
          onTap: controller.current != null ? controller.previous : null,
        ),
        PlayPauseButton(
          isPlaying: controller.isPlaying,
          isLoading: controller.isLoading,
          size: 74,
          onTap: controller.togglePlayPause,
        ),
        _TransportIcon(
          icon: PlayerIcons.next,
          tooltip: l10n.playerNext,
          onTap: canSkip ? controller.next : null,
        ),
        _ToggleIcon(
          icon: repeatMode == PlayerRepeatMode.one
              ? PlayerIcons.repeatOne
              : PlayerIcons.repeat,
          active: repeatMode != PlayerRepeatMode.off,
          tooltip: l10n.playerRepeat,
          onTap: controller.cycleRepeatMode,
        ),
      ],
    );
  }
}

/// Melodia gradyanlı, dairesel oynat/duraklat butonu.
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.size,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: isPlaying ? l10n.playerPause : l10n.playerPlay,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.playGradient,
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isLoading ? null : onTap,
            child: Center(
              child: isLoading
                  ? SizedBox.square(
                      dimension: size * 0.34,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isPlaying ? PlayerIcons.pause : PlayerIcons.play,
                        key: ValueKey(isPlaying),
                        color: Colors.white,
                        size: size * 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransportIcon extends StatelessWidget {
  const _TransportIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      iconSize: 36,
      color: Colors.white,
      disabledColor: Colors.white.withValues(alpha: 0.3),
      icon: Icon(icon),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  const _ToggleIcon({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            onPressed: onTap,
            tooltip: tooltip,
            iconSize: 22,
            color: active ? AppColors.pink : AppColors.textSecondary,
            icon: Icon(icon),
          ),
          if (active)
            Positioned(
              bottom: 4,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.pink,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
