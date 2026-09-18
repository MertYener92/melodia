import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';

/// Profile ekranındaki "Songs" bölümü için kompakt, minimal şarkı satırı.
///
/// widgets/song_tile.dart'tan (Kütüphane sekmesinde kullanılan, 64px
/// artwork + kalp/menü aksiyonlu, kendi kartlı versiyon) BİLİNÇLİ olarak
/// ayrı tutuldu -- burası profilin bir ALT bölümü, her satır ayrı bir
/// "kart" gibi durmamalı (madde 9: "devasa kartlardan oluşmamalı"),
/// sadece ince bir ayırıcıyla birbirinden ayrılan, premium bir müzik
/// streaming listesi hissi vermeli. Aksiyon: sadece dokununca çal.
class SongListItem extends StatelessWidget {
  const SongListItem({
    super.key,
    required this.librarySong,
    required this.onTap,
    this.isPlaying = false,
  });

  final LibrarySong librarySong;
  final VoidCallback onTap;
  final bool isPlaying;

  static const double _artSize = 52;

  String _formatDuration(double? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final total = Duration(seconds: seconds.round());
    final m = total.inMinutes.remainder(60).toString();
    final s = total.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _art(Song song) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: song.imageUrl.isNotEmpty
          ? Image.network(
              song.imageUrl,
              width: _artSize,
              height: _artSize,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: _artSize,
      height: _artSize,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = librarySong.song;
    final duration = _formatDuration(song.duration);
    final genre = librarySong.genre.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _art(song),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title.isEmpty ? 'Adsız şarkı' : song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPlaying ? AppColors.purple : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [if (genre.isNotEmpty) genre, if (duration.isNotEmpty) duration]
                          .join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                color: isPlaying ? AppColors.purple : AppColors.textSecondary,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
