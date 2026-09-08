import 'package:flutter/material.dart';
import '../services/music_video_service.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import 'video_library_screen.dart';

/// "Favorilerim" ekranı -- hem favori işaretlenmiş şarkıları hem de
/// favori işaretlenmiş video kliplerini tek listede gösterir.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.songLibrary,
    required this.player,
    required this.videoService,
  });

  final SongLibrary songLibrary;
  final PlayerController player;
  final MusicVideoService videoService;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Map<String, dynamic>>> _videoFuture = widget.videoService.fetchProjects();

  Future<void> _refresh() async {
    setState(() => _videoFuture = widget.videoService.fetchProjects());
    await Future.wait([_videoFuture, widget.songLibrary.loadFromBackend()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorilerim')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: AppColors.pink,
            onRefresh: _refresh,
            child: ListenableBuilder(
              listenable: widget.songLibrary,
              builder: (context, _) {
                final favoriteSongs =
                    widget.songLibrary.songs.where((s) => s.isFavorite).toList();

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _videoFuture,
                  builder: (context, snapshot) {
                    final favoriteVideos = (snapshot.data ?? [])
                        .where((p) => p['isFavorite'] == true)
                        .toList();

                    if (favoriteSongs.isEmpty &&
                        favoriteVideos.isEmpty &&
                        snapshot.connectionState == ConnectionState.done) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'Henüz favori eklemedin',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(
                              'Şarkı ya da klip oynatırken ♥ ikonuna bas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        if (favoriteSongs.isNotEmpty) ...[
                          const Text(
                            'Şarkılar',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...favoriteSongs.map((s) => SongTile(
                                librarySong: s,
                                isPlaying: widget.player.current?.song.id == s.song.id && widget.player.isPlaying,
                                onTap: () => widget.player.playSong(s),
                              )),
                          const SizedBox(height: 16),
                        ],
                        if (favoriteVideos.isNotEmpty) ...[
                          const Text(
                            'Videolar',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...favoriteVideos.map((p) => _FavoriteVideoTile(
                                project: p,
                                videoService: widget.videoService,
                              )),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteVideoTile extends StatelessWidget {
  const _FavoriteVideoTile({required this.project, required this.videoService});

  final Map<String, dynamic> project;
  final MusicVideoService videoService;

  @override
  Widget build(BuildContext context) {
    final title = project['songTitle']?.toString() ?? 'Adsız klip';
    final isReady = project['hasFinalVideo'] == true;
    final projectId = project['projectId']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppColors.glassCard(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isReady
              ? () => openClipPlayer(context, title: title, projectId: projectId, videoService: videoService)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: isReady ? AppColors.primaryGradient : null,
                    color: isReady ? null : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isReady ? Icons.play_arrow_rounded : Icons.hourglass_top_rounded,
                    color: isReady ? Colors.white : AppColors.textMuted,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.favorite_rounded, color: AppColors.pink, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}