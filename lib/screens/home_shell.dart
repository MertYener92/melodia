import 'package:flutter/material.dart';
import '../services/music_spec_service.dart';
import '../services/music_video_service.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/premium_bottom_nav.dart';
import 'create_screen.dart';
import 'discover_screen.dart';
import 'my_songs_screen.dart';
import 'player_screen.dart';
import 'profile_screen.dart';
import 'video_clip_screen.dart';

/// Bottom navigation bar ile AI Müzik / AI Video / My Songs / Discover /
/// Profile sekmelerini bir arada tutan ana kabuk widget'ı.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.service,
    required this.musicSpecService,
    required this.musicVideoService,
  });

  final SunoApiService service;
  final MusicSpecService musicSpecService;
  final MusicVideoService musicVideoService;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final SongLibrary _library;
  late final PlayerController _player;

  @override
  void initState() {
    super.initState();
    _library = SongLibrary(service: widget.service);
    _library.loadFromBackend();
    _player = PlayerController();
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
      const VideoClipScreen(),
      MySongsScreen(library: _library, player: _player),
      const DiscoverScreen(),
      ProfileScreen(library: _library),
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
                  NavItemData(icon: Icons.movie_creation_rounded, label: 'AI Video'),
                  NavItemData(
                    icon: Icons.album_rounded,
                    label: 'My Songs',
                  ),
                  NavItemData(icon: Icons.public_rounded, label: 'Discover'),
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