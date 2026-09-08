import 'package:flutter/material.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';

/// Bir şarkıyı liste halinde gösteren, glassmorphism görünümlü kart.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.librarySong,
    required this.onTap,
    this.onMore,
    this.isPlaying = false,
  });

  final LibrarySong librarySong;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final song = librarySong.song;
    // DEĞİŞTİ: "Genre · Süre" yerine "Genre | Mood" -- referans
    // tasarımdaki gibi ("Elektronik | Yükseltici" formatı).
    final subtitleParts = [
      if (librarySong.genre.isNotEmpty) librarySong.genre,
      if (librarySong.mood.isNotEmpty) librarySong.mood,
    ];
    final subtitle = subtitleParts.isEmpty ? '—' : subtitleParts.join(' | ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppColors.glassCard(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: song.imageUrl.isNotEmpty
                      ? Image.network(
                          song.imageUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderArt(),
                        )
                      : _placeholderArt(),
                ),
                const SizedBox(width: 14),
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
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // DEĞİŞTİ: Ayrı play/pause ikonu kaldırıldı -- satırın
                // kendisine basmak zaten çalıyor (onTap). Sadece "..."
                // kaldı, referans tasarımdaki gibi.
                if (onMore != null)
                  IconButton(
                    onPressed: onMore,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 24),
    );
  }
}