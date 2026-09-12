import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/music_spec_service.dart';
import '../services/music_video_service.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/premium_bottom_nav.dart';
import 'create_screen.dart';
import 'ai_video_screen.dart';
import 'library_screen.dart';
import 'player_screen.dart';
import 'profile_screen.dart';

/// Bottom navigation bar ile AI Müzik / My Songs / Kütüphane / Profile
/// sekmelerini bir arada tutan ana kabuk widget'ı.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.service,
    required this.musicSpecService,
    required this.musicVideoService,
    required this.authService,
    required this.onLoggedOut,
  });

  final SunoApiService service;
  final MusicSpecService musicSpecService;
  final MusicVideoService musicVideoService;
  final AuthService authService;

  /// Çıkış yapıldığında ya da hesap silindiğinde çağrılır (login
  /// ekranına dönmek için).
  final VoidCallback onLoggedOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final SongLibrary _library;
  late final PlayerController _player;
  bool _imagesPrecached = false;

  @override
  void initState() {
    super.initState();
    _library = SongLibrary(service: widget.service);
    _library.loadFromBackend();
    _player = PlayerController(service: widget.service);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // DÜZELTME ("premium hissi" sorunu): Kütüphane sekmesindeki arka
    // plan görselleri (AssetImage) daha önce SADECE o sekmeye ilk kez
    // gidildiğinde decode ediliyordu -- bu da görsellerin ~1 saniye
    // gecikmeyle "pat" diye belirmesine (pop-in) sebep oluyordu. Burada
    // uygulama İLK AÇILDIĞI ANDA (hangi sekmede olursa olsun), bu dört
    // görseli arka planda önceden decode ediyoruz. Kullanıcı Kütüphane'ye
    // geçtiğinde görseller zaten Flutter'ın global image cache'inde
    // hazır bulunuyor, anında ve pürüzsüz görünüyor.
    if (!_imagesPrecached) {
      _imagesPrecached = true;
      for (final path in const [
        'assets/images/library_songs.png',
        'assets/images/library_videos.png',
        'assets/images/library_favorites.png',
        'assets/images/library_downloads.png',
      ]) {
        precacheImage(AssetImage(path), context);
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _library.dispose();
    super.dispose();
  }

  void _goToTab(int index) => setState(() => _index = index);

  void _openPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          controller: _player,
          service: widget.service,
          musicVideoService: widget.musicVideoService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CreateScreen(
        service: widget.service,
        musicSpecService: widget.musicSpecService,
        library: _library,
        isActive: _index == 0,
      ),
      const AiVideoScreen(),
      LibraryScreen(
        songLibrary: _library,
        player: _player,
        videoService: widget.musicVideoService,
      ),
      ProfileScreen(
        library: _library,
        service: widget.service,
        authService: widget.authService,
        onLoggedOut: widget.onLoggedOut,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: IndexedStack(index: _index, children: screens),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListenableBuilder(
                listenable: _player,
                builder: (context, _) => MiniPlayerBar(
                  controller: _player,
                  onTap: _openPlayer,
                ),
              ),
              PremiumBottomNav(
                currentIndex: _index,
                onTap: _goToTab,
                items: const [
                  NavItemData(icon: Icons.home_rounded, label: 'AI Müzik'),
                  NavItemData(
                    icon: Icons.movie_creation_rounded,
                    label: 'AI Video',
                  ),
                  NavItemData(icon: Icons.video_library_rounded, label: 'Kütüphane'),
                  NavItemData(icon: Icons.person_rounded, label: 'Profile'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}