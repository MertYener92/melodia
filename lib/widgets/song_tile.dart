import 'package:flutter/material.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';

/// Bir şarkıyı liste halinde gösteren kart.
///
/// DEĞİŞTİ (referans tasarıma göre revize): Artık kare kapak görselinin
/// SOL ALT köşesinde süre bilgisi küçük bir koyu rozet olarak görünüyor
/// (ayrı bir metin satırı değil). Başlığın yanında, şarkının hangi
/// motorla üretildiğini gösteren küçük gri bir etiket var (SUNO/LYRIA).
/// Genre/mood alt satırı kaldırıldı -- referans tasarımda sadece
/// başlık + motor etiketi var. Kart artık ayrı bir "glass" arka plan
/// kutusu içinde değil, düz bir liste satırı (referans tasarımdaki gibi).
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

  String _formatDuration(double? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final total = Duration(seconds: seconds.round());
    final m = total.inMinutes.remainder(60).toString();
    final s = total.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final song = librarySong.song;
    final durationText = _formatDuration(song.duration);
    // Motor etiketi: "suno" -> "SUNO", "lyria" -> "LYRIA". Bilinmeyen/boş
    // bir değer gelirse (eski kayıtlar) sessizce gösterilmez.
    final providerTag = song.provider.trim().toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: song.imageUrl.isNotEmpty
                        ? Image.network(
                            song.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholderArt(),
                          )
                        : _placeholderArt(),
                  ),
                  // YENİ: Süre artık ayrı bir metin satırı değil, kapak
                  // görselinin sol alt köşesinde küçük bir rozet.
                  if (durationText.isNotEmpty)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          durationText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (providerTag.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        providerTag,
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
    );
  }

  Widget _placeholderArt() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 22),
    );
  }
}