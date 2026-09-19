import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';

import '../../services/song_library.dart';
import '../../theme/app_theme.dart';

/// Mini player ile tam ekran player arasında kapak görselinin "büyüyerek"
/// geçmesi için ortak Hero etiketi. Aynı anda yalnızca bir mini player
/// olduğu için sabit bir etiket yeterli.
const String kPlayerArtworkHeroTag = 'melodia-player-artwork';

/// Player'daki tüm ikonlar tek aileden (Material "rounded") gelsin diye
/// tek yerde toplanıyor -- farklı ekranlarda karışık stil kullanılmasın.
class PlayerIcons {
  PlayerIcons._();

  static const IconData minimize = Icons.keyboard_arrow_down_rounded;
  static const IconData more = Icons.more_horiz_rounded;
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData previous = Icons.fast_rewind_rounded;
  static const IconData next = Icons.fast_forward_rounded;
  static const IconData shuffle = Icons.shuffle_rounded;
  static const IconData repeat = Icons.repeat_rounded;
  static const IconData repeatOne = Icons.repeat_one_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData favoriteOutline = Icons.favorite_border_rounded;
  static const IconData remix = Icons.autorenew_rounded;
  static const IconData share = Icons.ios_share_rounded;
  static const IconData playlist = Icons.playlist_add_rounded;
  static const IconData comment = Icons.chat_bubble_outline_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData lyrics = Icons.lyrics_outlined;
  static const IconData video = Icons.movie_creation_outlined;
  static const IconData placeholder = Icons.music_note_rounded;
}

/// "Pop · Enerjik" gibi alt başlık; tür/ruh hali yoksa "AI ile üretildi".
String playerSubtitle(LibrarySong song, AppLocalizations l10n) {
  final parts = [
    if (song.genre.isNotEmpty) song.genre,
    if (song.mood.isNotEmpty) song.mood,
  ];
  return parts.isEmpty ? l10n.playerAiGenerated : parts.join(' · ');
}

/// Kare, köşeleri yuvarlatılmış şarkı kapağı. Görsel yoksa ya da
/// yüklenemezse Melodia gradyanlı bir yer tutucu gösterir; görsel asla
/// esnetilmez (BoxFit.cover + kare kutu).
class SongArtwork extends StatelessWidget {
  const SongArtwork({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.radius,
    this.heroTag,
  });

  final String imageUrl;
  final double size;
  final double radius;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final art = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: imageUrl.isEmpty
            ? _Placeholder(size: size)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _Placeholder(size: size),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : _Placeholder(size: size, dimmed: true),
              ),
      ),
    );
    if (heroTag == null) return art;
    return Hero(tag: heroTag!, child: art);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size, this.dimmed = false});

  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: dimmed ? null : AppColors.primaryGradient,
        color: dimmed ? AppColors.surfaceElevated : null,
      ),
      child: Center(
        child: Icon(
          PlayerIcons.placeholder,
          color: Colors.white.withValues(alpha: dimmed ? 0.25 : 0.9),
          size: size * 0.32,
        ),
      ),
    );
  }
}
