import 'package:flutter/material.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.library,
    required this.player,
    required this.onGoToCreate,
  });

  final SongLibrary library;
  final PlayerController player;
  final VoidCallback onGoToCreate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([library, player]),
        builder: (context, _) {
          final recent = library.songs.take(5).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildQuickCreateCard(context),
              const SizedBox(height: 28),
              const Text(
                'Your recent songs',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              if (recent.isEmpty)
                _buildEmptyState()
              else
                ...recent.map(
                  (s) => SongTile(
                    librarySong: s,
                    isPlaying:
                        player.current?.song.id == s.song.id &&
                        player.isPlaying,
                    onTap: () => player.playSong(s),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.music_note, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'Melodia Studio',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.surfaceElevated,
          child: Icon(Icons.person, color: AppColors.textSecondary, size: 20),
        ),
      ],
    );
  }

  Widget _buildQuickCreateCard(BuildContext context) {
    return GestureDetector(
      onTap: onGoToCreate,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create your next song',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Turn your ideas into music with AI',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppColors.glassCard(),
      child: const Column(
        children: [
          Icon(Icons.library_music_outlined,
              color: AppColors.textMuted, size: 36),
          SizedBox(height: 10),
          Text(
            'No songs yet — create your first one!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}