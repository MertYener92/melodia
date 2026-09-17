import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../services/music_video_service.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';
import 'downloads_screen.dart';
import 'favorites_screen.dart';
import 'my_songs_screen.dart';
import 'video_library_screen.dart';

/// "Kütüphane" sekmesi: kullanıcının tüm yaratımlarına (şarkılar +
/// video klipler + favoriler + indirdikleri) tek bir giriş noktasından
/// ulaştığı hub ekranı.
///
/// DEĞİŞTİ: Kartlar artık 2x2 dikey grid yerine YATAY kaydırmalı tek
/// bir sırada. Her kart neredeyse tam ekran genişliğinde, bir sonraki
/// kartın kenarı hafifçe görünerek kaydırılabilir olduğunu ima ediyor.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.songLibrary,
    required this.player,
    required this.videoService,
  });

  final SongLibrary songLibrary;
  final PlayerController player;
  final MusicVideoService videoService;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: ListenableBuilder(
          listenable: songLibrary,
          builder: (context, _) {
            return ListView(
              children: [
                const _LibraryHero(),
                const SizedBox(height: 20),
                _LibraryHubCard(
                  title: l10n.librarySongsTitle,
                  subtitle: l10n.librarySongsSubtitle,
                  icon: Icons.music_note_rounded,
                  accentColor: AppColors.pink,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MySongsScreen(library: songLibrary, player: player),
                    ),
                  ),
                ),
                _VideoLibraryHubCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoLibraryScreen(videoService: videoService),
                    ),
                  ),
                ),
                _LibraryHubCard(
                  title: l10n.libraryFavoritesTitle,
                  subtitle: l10n.libraryFavoritesSubtitle,
                  icon: Icons.favorite_rounded,
                  accentColor: const Color(0xFFE0457B),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FavoritesScreen(
                        songLibrary: songLibrary,
                        player: player,
                        videoService: videoService,
                      ),
                    ),
                  ),
                ),
                _LibraryHubCard(
                  title: l10n.libraryDownloadsTitle,
                  subtitle: l10n.libraryDownloadsSubtitle,
                  icon: Icons.download_rounded,
                  accentColor: const Color(0xFF2FA36B),
                  showDivider: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Kütüphane sekmesinin üst kısmındaki "kapak" bölümü: kullanıcının
/// hazırladığı plak (vinil) görseli arka plan, üzerinde başlık, ilham
/// verici bir alıntı ve küçük bir etiket satırı. Görsel dosyası
/// assets/images/library_hero.png konumuna eklenmelidir (assets/images/
/// klasörü pubspec.yaml'da zaten tanımlı, ayrı bir kayıt gerekmiyor).
class _LibraryHero extends StatelessWidget {
  const _LibraryHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // DÜZELTME: plak görselinin arkasındaki koyu gradyan katmanı
    // ("siyah konteyner" geri bildirimi) TAMAMEN kaldırıldı -- artık
    // sadece görsel görünüyor. Okunabilirlik için (bir arka plan kutusu
    // yerine) metinlere ince bir gölge eklendi. Alıntı metni kaldırıldı,
    // "YARAT · KEŞFET · SAKLA" etiketi artık görselin en altında, ortalı.
    const textShadow = [
      Shadow(color: Color(0xAA000000), blurRadius: 10, offset: Offset(0, 1)),
    ];
    return Container(
      height: 270,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColors.surfaceElevated,
        image: const DecorationImage(
          image: AssetImage('assets/images/library_hero.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.libraryHeroTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      shadows: textShadow,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.libraryHeroSubtitle,
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.9),
                      fontSize: 14,
                      shadows: textShadow,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: Text(
                  l10n.libraryTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    shadows: textShadow,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Videolarım satırı için ince bir sarmalayıcı (l10n metinlerini
/// _LibraryHubCard'a bağlıyor). DÜZELTME: Sadeleştirilmiş tasarımda video
/// sayısı artık gösterilmediği için önceki asenkron (fetchProjects
/// + StatefulWidget) yapıya gerek kalmadı, düz bir StatelessWidget'a
/// indirgendi.
class _VideoLibraryHubCard extends StatelessWidget {
  const _VideoLibraryHubCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // NOT: Sadeleştirilmiş tasarımda artık video sayısını göstermiyoruz
    // (referans görseldeki gibi sade bir satır) -- bu yüzden projeleri
    // ayrıca çekmeye de gerek kalmadı.
    return _LibraryHubCard(
      title: l10n.libraryVideosTitle,
      subtitle: l10n.libraryVideosSubtitle,
      icon: Icons.play_arrow_rounded,
      accentColor: const Color(0xFF3B82F6),
      onTap: onTap,
    );
  }
}

/// Kütüphane hub'ındaki her satır (Şarkılarım/Videolarım/Favorilerim/
/// İndirdiklerim). DEĞİŞTİ: Önceki görsel/gradient kart tasarımı yerine
/// referans tasarımdaki gibi sade bir liste satırı -- renkli yuvarlak
/// köşeli ikon kare + başlık + alt yazı + sağda ok, aralarında ince bir
/// ayraç çizgisi.
class _LibraryHubCard extends StatelessWidget {
  const _LibraryHubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  /// Son satırdan sonra ayraç çizgisi gösterilmesin diye.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}