import 'package:flutter/material.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class MySongsScreen extends StatefulWidget {
  const MySongsScreen({
    super.key,
    required this.library,
    required this.player,
  });

  final SongLibrary library;
  final PlayerController player;

  @override
  State<MySongsScreen> createState() => _MySongsScreenState();
}

class _MySongsScreenState extends State<MySongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.library, widget.player]),
        builder: (context, _) {
          var songs = widget.library.songs;
          if (_favoritesOnly) {
            songs = songs.where((s) => s.isFavorite).toList();
          }
          if (_query.isNotEmpty) {
            songs = songs
                .where(
                  (s) => s.song.title
                      .toLowerCase()
                      .contains(_query.toLowerCase()),
                )
                .toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      'My Songs',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _favoritesOnly = !_favoritesOnly),
                      icon: Icon(
                        _favoritesOnly
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _favoritesOnly
                            ? AppColors.pink
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search songs...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textMuted,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: songs.isEmpty
                    ? const Center(
                        child: Text(
                          'No songs found',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final s = songs[index];
                          return SongTile(
                            librarySong: s,
                            isPlaying:
                                widget.player.current?.song.id ==
                                    s.song.id &&
                                widget.player.isPlaying,
                            onTap: () => widget.player.playSong(s),
                            onMore: () => _showActions(context, s),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showActions(BuildContext context, LibrarySong song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  song.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.pink,
                ),
                title: Text(
                  song.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  widget.library.toggleFavorite(song);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                ),
                title: const Text(
                  'Rename',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, song);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.share_outlined,
                  color: AppColors.textSecondary,
                ),
                title: const Text(
                  'Share',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Share: audioUrl\'i paylaşım paketiyle (share_plus) '
                        'entegre edebiliriz.',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.download_outlined,
                  color: AppColors.textSecondary,
                ),
                title: const Text(
                  'Download',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Download: dosya indirme için path_provider + '
                        'dio/http entegrasyonu eklenmeli.',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  widget.library.remove(song);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, LibrarySong song) {
    final controller = TextEditingController(text: song.song.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text(
          'Rename song',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.library.rename(song, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}