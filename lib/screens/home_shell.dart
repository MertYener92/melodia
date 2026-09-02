import 'package:flutter/material.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import 'create_screen.dart';
import 'discover_screen.dart';
import 'home_screen.dart';
import 'my_songs_screen.dart';
import 'player_screen.dart';
import 'profile_screen.dart';

/// Bottom navigation bar ile Home / Create / My Songs / Discover /
/// Profile sekmelerini bir arada tutan ana kabuk widget'ı.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.service});

  final SunoApiService service;

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
    _library = SongLibrary();
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
        builder: (_) => PlayerScreen(controller: _player),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        library: _library,
        player: _player,
        onGoToCreate: () => _goToTab(1),
      ),
      CreateScreen(service: widget.service, library: _library),
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
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: const Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: _index == 0,
                      onTap: () => _goToTab(0),
                    ),
                    _NavItem(
                      icon: Icons.add_circle_rounded,
                      label: 'Create',
                      isSelected: _index == 1,
                      onTap: () => _goToTab(1),
                    ),
                    _NavItem(
                      icon: Icons.library_music_rounded,
                      label: 'My Songs',
                      isSelected: _index == 2,
                      onTap: () => _goToTab(2),
                    ),
                    _NavItem(
                      icon: Icons.explore_rounded,
                      label: 'Discover',
                      isSelected: _index == 3,
                      onTap: () => _goToTab(3),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isSelected: _index == 4,
                      onTap: () => _goToTab(4),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.purple : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}