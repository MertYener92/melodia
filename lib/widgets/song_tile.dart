import 'package:flutter/material.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';

/// Bir şarkıyı liste halinde gösteren kart.
///
/// DEĞİŞTİ (referans tasarıma göre revize): her satır artık kendi
/// ÇERÇEVESİ (border + hafif arka plan) içinde, ayrı bir kart gibi
/// duruyor -- önceden sadece düz bir liste satırıydı. Başlığın altına
/// söz/prompt satırı, onun altına da AYRI bir "tarih • tür" satırı
/// eklendi. Sağda artık "..." menüsünün yanında DOKUNULABİLİR bir kalp
/// ikonu var -- basınca favori durumu ANINDA değişiyor, menüye girmeye
/// gerek yok (menüdeki favori seçeneği de duruyor, ikisi aynı işlevi
/// yapıyor).
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.librarySong,
    required this.onTap,
    this.onMore,
    this.onToggleFavorite,
    this.isPlaying = false,
  });

  final LibrarySong librarySong;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final VoidCallback? onToggleFavorite;
  final bool isPlaying;

  static const double _coverSize = 64;

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

  /// YENİ: "17 Eyl 2025 • Pop" gibi ayrı bir alt satır -- prompt/detay
  /// metninden BAĞIMSIZ, referans görseldeki gibi.
  String _dateGenreText(LibrarySong librarySong) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    final d = librarySong.createdAt;
    final dateStr = '${d.day} ${months[d.month - 1]} ${d.year}';
    final genre = librarySong.genre.trim();
    return genre.isEmpty ? dateStr : '$dateStr • $genre';
  }

  @override
  Widget build(BuildContext context) {
    final song = librarySong.song;
    final durationText = _formatDuration(song.duration);
    // Motor etiketi: "suno" -> "SUNO", "lyria" -> "LYRIA". Bilinmeyen/boş
    // bir değer gelirse (eski kayıtlar) sessizce gösterilmez.
    final providerTag = song.provider.trim().toUpperCase();
    final detailText = _detailText(librarySong);
    final dateGenreText = _dateGenreText(librarySong);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
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
                    if (durationText.isNotEmpty)
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(5),
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
                                fontSize: 15.5,
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
                                fontSize: 10.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (detailText.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          detailText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        dateGenreText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                if (onToggleFavorite != null)
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      librarySong.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: librarySong.isFavorite ? AppColors.pink : AppColors.textMuted,
                    ),
                  ),
                if (onMore != null)
                  IconButton(
                    onPressed: onMore,
                    icon: const Icon(
                      Icons.more_vert_rounded,
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
      width: _coverSize,
      height: _coverSize,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 24),
    );
  }
}
