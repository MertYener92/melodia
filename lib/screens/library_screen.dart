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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: ListenableBuilder(
          listenable: songLibrary,
          builder: (context, _) {
            final songCount = songLibrary.songs.length;
            final favoriteCount = songLibrary.songs.where((s) => s.isFavorite).length;

            return ListView(
              children: [
                const _LibraryHero(),
                const SizedBox(height: 20),
                _LibraryHubCard(
                  title: 'Şarkılarım',
                  subtitle: 'Ürettiğin tüm şarkılar.',
                  countLabel: '$songCount şarkı',
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
                _VideoLibraryHubCard(
                  videoService: videoService,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoLibraryScreen(videoService: videoService),
                    ),
                  ),
                ),
                _LibraryHubCard(
                  title: 'Favorilerim',
                  subtitle: 'Beğendiğin içerikler.',
                  countLabel: '$favoriteCount içerik',
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
                  // NOT: Henüz gerçek indirme takibi yok, bu yüzden
                  // burada sahte bir sayı GÖSTERMİYORUZ (bkz.
                  // downloads_screen.dart) — takip eklenince buraya
                  // gerçek bir sayaç bağlanabilir.
                  countLabel: null,
                  icon: Icons.download_rounded,
                  imagePath: 'assets/images/library_downloads.png',
                  fallbackColors: const [Color(0xFF0A3A22), Color(0xFF07140D)],
                  accentColor: const Color(0xFF34D399),
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
    return Container(
      height: 340,
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
            // Üstte başlığın, altta alıntı/etiketin okunabilmesi için
            // yukarı ve aşağı doğru koyulaşan gradient — orta kısımda
            // plak görseli net kalıyor.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.28, 0.62, 1.0],
                  colors: [
                    Color(0xCC0A0A12),
                    Color(0x330A0A12),
                    Color(0x550A0A12),
                    Color(0xEE0A0A12),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kütüphane',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tüm yaratımların burada.',
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.75),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '“',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          height: 0.6,
                        ),
                      ),
                      const Text(
                        'İyi fikirler\nher zaman\nbir yerlerde saklıdır.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 40,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'YARAT  ·  KEŞFET  ·  SAKLA',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ],
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

/// Video sayısı `fetchProjects()` ile asenkron geldiği için ayrı bir
/// sarmalayıcı. DÜZELTME: Bu artık StatefulWidget -- Future SADECE bir
/// kez (initState'te) oluşturuluyor ve saklanıyor. Önceki (Stateless +
/// build() içinde `future:` oluşturma) yaklaşımı, LibraryScreen'in
/// üstündeki ListenableBuilder her rebuild olduğunda (ör. bir şarkı
/// favorilenince) bu widget'ı da yeniden build ediyor, bu da HER
/// SEFERİNDE ağa yeni bir istek atıp video sayısını kısa süreliğine
/// kaybolup tekrar belirmesine (titreşim/gecikme hissi) sebep oluyordu.
class _VideoLibraryHubCard extends StatefulWidget {
  const _VideoLibraryHubCard({required this.videoService, required this.onTap});

  final MusicVideoService videoService;
  final VoidCallback onTap;

  @override
  State<_VideoLibraryHubCard> createState() => _VideoLibraryHubCardState();
}

class _VideoLibraryHubCardState extends State<_VideoLibraryHubCard> {
  late final Future<List<Map<String, dynamic>>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = widget.videoService.fetchProjects();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _projectsFuture,
      builder: (context, snapshot) {
        final count = snapshot.data?.length;
        return _LibraryHubCard(
          title: 'Videolarım',
          subtitle: 'Ürettiğin tüm videolar.',
          countLabel: count == null ? null : '$count video',
          icon: Icons.play_arrow_rounded,
          imagePath: 'assets/images/library_videos.png',
          fallbackColors: const [Color(0xFF0A2340), Color(0xFF071018)],
          accentColor: const Color(0xFF3B82F6),
          onTap: widget.onTap,
        );
      },
    );
  }
}

class _LibraryHubCard extends StatelessWidget {
  const _LibraryHubCard({
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.icon,
    required this.imagePath,
    required this.fallbackColors,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;

  /// Örn. "24 şarkı". Gerçek veri henüz yoksa/yüklenmediyse null geç —
  /// o zaman bu satır hiç gösterilmez, uydurma bir sayı basılmaz.
  final String? countLabel;
  final IconData icon;

  /// assets/images/ altındaki arkaplan fotoğrafı. Dosya yoksa/yüklenemezse
  /// [fallbackColors] ile bir gradient gösterilir.
  final String imagePath;
  final List<Color> fallbackColors;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 92,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: fallbackColors,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Görsel artık kırpılmıyor (BoxFit.contain) — yıldız, kamera
              // gibi ikonlar tam görünür. Sağda sabit genişlikli bir kutu
              // içinde, dikeyde ortalanmış şekilde yerleşiyor.
              // Görsel artık sağ tarafta daha geniş bir alanda (kart
              // genişliğinin ~65%'i) ve SOL kenarı ShaderMask ile
              // şeffaflaşarak arka plan gradyanına karışıyor -- önceki
              // versiyonda görsel sert kenarlı bir "kare/yama" gibi
              // duruyordu, bu artık yumuşak bir geçişle çözülüyor.
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.68,
                  heightFactor: 1,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, Colors.black, Colors.black],
                      stops: [0.0, 0.45, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              // Soldan sağa karartma -- metin sol tarafta, görsel sağda
              // net kalıyor (referans tasarımdaki gibi).
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.88),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.15),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: Colors.white, size: 20),
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
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          if (countLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              countLabel!,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.32),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 15,
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