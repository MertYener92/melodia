import 'package:flutter/material.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';

/// Bir şarkıyı liste halinde gösteren kart.
///
/// DEĞİŞTİ (referans tasarıma göre revize): Kapak görseli büyütüldü
/// (56 -> 76) -- önceki boyut çok küçük duruyordu. Başlığın altına,
/// gri tonda, en fazla 2 satır (uzunsa sonu "..." ile kesilen) bir
/// "şarkı detayı" satırı eklendi -- şarkının üretim prompt'u (varsa),
/// yoksa genre/mood'un birleşimi kullanılıyor. Süre bilgisi artık kapak
/// görselinin sol alt köşesinde küçük bir koyu rozet olarak görünüyor
/// (ayrı bir metin satırı değil). Başlığın yanında, şarkının hangi
/// motorla üretildiğini gösteren küçük gri bir etiket var (SUNO/LYRIA).
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

  static const double _coverSize = 76;

  String _formatDuration(double? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final total = Duration(seconds: seconds.round());
    final m = total.inMinutes.remainder(60).toString();
    final s = total.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Başlığın altında gösterilecek gri "şarkı detayı" metni -- önce
  /// şarkının üretim prompt'u (song.prompt) denenir, o boşsa (ör. eski
  /// bir kayıt) genre/mood'un birleşimine düşülür. İkisi de boşsa
  /// hiçbir alt satır gösterilmez.
  String _detailText(LibrarySong librarySong) {
    final prompt = librarySong.song.prompt.trim();
    if (prompt.isNotEmpty) return prompt;
    final parts = [librarySong.genre, librarySong.mood]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final song = librarySong.song;
    final durationText = _formatDuration(song.duration);
    // Motor etiketi: "suno" -> "SUNO", "lyria" -> "LYRIA". Bilinmeyen/boş
    // bir değer gelirse (eski kayıtlar) sessizce gösterilmez.
    final providerTag = song.provider.trim().toUpperCase();
    final detailText = _detailText(librarySong);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: song.imageUrl.isNotEmpty
                        ? Image.network(
                            song.imageUrl,
                            width: _coverSize,
                            height: _coverSize,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholderArt(),
                          )
                        : _placeholderArt(),
                  ),
                  // YENİ: Süre artık ayrı bir metin satırı değil, kapak
                  // görselinin sol alt köşesinde küçük bir rozet.
                  if (durationText.isNotEmpty)
                    Positioned(
                      left: 5,
                      bottom: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          durationText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
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
                              fontSize: 16,
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
                    if (detailText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        detailText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.3,
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
      width: _coverSize,
      height: _coverSize,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 28),
    );
  }
}