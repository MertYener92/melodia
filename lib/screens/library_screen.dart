import 'package:flutter/material.dart';
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
/// ulaştığı hub ekranı. 2x2 görsel kart grid'i.
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kütüphane',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tüm yaratımların burada.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                // DÜZELTME: 0.85 çok "kısa" kart üretiyordu, içerik
                // taşıyordu (BOTTOM OVERFLOWED). 0.72 kartı belirgin
                // şekilde uzatıp içeriğe daha fazla dikey alan veriyor.
                childAspectRatio: 0.72,
                children: [
                  _LibraryHubCard(
                    title: 'Şarkılarım',
                    subtitle: 'Ürettiğin tüm şarkılar.',
                    icon: Icons.music_note_rounded,
                    imagePath: 'assets/images/library_songs.png',
                    fallbackColors: const [Color(0xFF3A0A2E), Color(0xFF120714)],
                    accentColor: AppColors.pink,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Şarkılarım')),
                          body: Container(
                            decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
                            child: MySongsScreen(library: songLibrary, player: player),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _LibraryHubCard(
                    title: 'Videolarım',
                    subtitle: 'Ürettiğin tüm videolar.',
                    icon: Icons.play_arrow_rounded,
                    imagePath: 'assets/images/library_videos.png',
                    fallbackColors: const [Color(0xFF0A2340), Color(0xFF071018)],
                    accentColor: const Color(0xFF3B82F6),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VideoLibraryScreen(videoService: videoService),
                      ),
                    ),
                  ),
                  _LibraryHubCard(
                    title: 'Favorilerim',
                    subtitle: 'Beğendiğin içerikler.',
                    icon: Icons.star_rounded,
                    imagePath: 'assets/images/library_favorites.png',
                    fallbackColors: const [Color(0xFF3A2A0A), Color(0xFF141007)],
                    accentColor: const Color(0xFFF5A623),
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
                    title: 'İndirdiklerim',
                    subtitle: 'Cihazına indirdiklerin.',
                    icon: Icons.download_rounded,
                    imagePath: 'assets/images/library_downloads.png',
                    fallbackColors: const [Color(0xFF0A3A22), Color(0xFF07140D)],
                    accentColor: const Color(0xFF34D399),
                    // NOT: Henüz gerçek indirme takibi yok, placeholder
                    // ekrana yönlendiriyor (bkz. downloads_screen.dart).
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryHubCard extends StatelessWidget {
  const _LibraryHubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imagePath,
    required this.fallbackColors,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// assets/images/ altındaki arkaplan fotoğrafı. pubspec.yaml'da
  /// "assets:" listesine eklenmiş olmalı. Dosya henüz yoksa (veya
  /// yüklenemezse) [fallbackColors] ile bir gradient gösterilir --
  /// böylece görseller eklenmeden önce de uygulama çökmez.
  final String imagePath;
  final List<Color> fallbackColors;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // DÜZELTME (kesin çözüm): Görsel ve çerçeve artık AYNI
        // BoxDecoration içinde çiziliyor -- Flutter ikisini tek bir
        // paint çağrısında, aynı köşe yuvarlamasıyla çiziyor. Önceki
        // sürümde görsel (ClipRRect) ve çerçeve (ayrı Container) farklı
        // katmanlardaydı; ikisinin anti-aliasing'i piksel bazında tam
        // örtüşmüyordu, bu da köşelerde "kesik" görünüme sebep oluyordu.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          color: fallbackColors.first, // görsel yüklenemezse görünen zemin
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            onError: (_, __) {}, // sessizce yut, zemin rengi görünsün
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23), // border kalınlığı kadar içeride
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Metnin okunabilir olması için karartma gradyanı.
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          // DEĞİŞTİ: tam opak yerine yarı saydam "cam"
                          // görünümü -- referans tasarımdaki gibi.
                          color: accentColor.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, color: Colors.white, size: 17),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        // DEĞİŞTİ: tam opak yerine yarı saydam "cam"
                        // görünümü -- referans tasarımdaki gibi.
                        color: accentColor.withValues(alpha: 0.32),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}