import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';

import '../services/auth_service.dart';
import '../services/music_video_service.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notice.dart';
import '../widgets/credit_badges.dart';
import '../widgets/generation_card.dart';
import '../widgets/library_list_item.dart';
import 'video_library_screen.dart';

enum LibraryFilter { all, music, video, remix }

/// "Kütüphane" sekmesi: kullanıcının tüm şarkıları, remix'leri ve klipleri
/// tek, yoğun bir listede -- büyük başlık, filtre çipleri, altında en yeni
/// önce sıralanmış satırlar. Şarkıya dokununca çalmaya başlar ve büyük
/// player açılır; klibe dokununca klip oynatıcısı açılır.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.songLibrary,
    required this.player,
    required this.videoService,
    required this.authService,
    required this.service,
    required this.onOpenSettings,
    required this.onOpenPlayer,
    this.isActive = false,
  });

  final SongLibrary songLibrary;
  final PlayerController player;
  final MusicVideoService videoService;
  final AuthService authService;
  final SunoApiService service;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenPlayer;

  /// Sekme görünür olduğunda klip listesi tazelenir (yeni klip üretilmiş
  /// olabilir).
  final bool isActive;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _Entry {
  _Entry.song(LibrarySong this.song) : video = null, createdAt = song.createdAt;

  _Entry.video(Map<String, dynamic> this.video)
    : song = null,
      createdAt =
          DateTime.tryParse(video['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

  final LibrarySong? song;
  final Map<String, dynamic>? video;
  final DateTime createdAt;
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilter _filter = LibraryFilter.all;
  List<Map<String, dynamic>> _videos = const [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await widget.videoService.fetchProjects();
      if (mounted) setState(() => _videos = videos);
    } catch (_) {
      // Klipler yüklenemezse şarkılar yine gösterilir; bir sonraki
      // sekme geçişinde ya da aşağı çekince tekrar denenir.
    }
  }

  Future<void> _refresh() async {
    await Future.wait([widget.songLibrary.loadFromBackend(), _loadVideos()]);
  }

  bool _isRemix(LibrarySong s) => s.mode == 'remix';

  List<_Entry> _entries() {
    final songs = widget.songLibrary.songs;
    final pending = songs.where((s) => s.pendingId != null).map(_Entry.song);
    final done = songs.where((s) => s.pendingId == null);

    final items = <_Entry>[
      if (_filter != LibraryFilter.video)
        ...done
            .where(
              (s) => switch (_filter) {
                LibraryFilter.music => !_isRemix(s),
                LibraryFilter.remix => _isRemix(s),
                _ => true,
              },
            )
            .map(_Entry.song),
      if (_filter == LibraryFilter.all || _filter == LibraryFilter.video)
        ..._videos.map(_Entry.video),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Devam eden üretimler hangi filtrede olursa olsun en üstte kalır --
    // kullanıcı üretimini her zaman takip edebilmeli.
    return [...pending, ...items];
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    try {
      return DateFormat.yMMMd(locale).format(date.toLocal());
    } catch (_) {
      return DateFormat('dd.MM.yyyy').format(date.toLocal());
    }
  }

  String _join(List<String> parts) =>
      parts.where((p) => p.trim().isNotEmpty).join(' · ');

  Future<void> _playSong(LibrarySong song) async {
    if (widget.player.current?.song.id != song.song.id) {
      // Player ekranı açılır açılmaz yükleniyor durumunu gösterir; çalma
      // hatası AppNotice olarak player/mini player tarafından yönetilir.
      widget.player.playSong(song);
    }
    widget.onOpenPlayer();
  }

  void _openVideo(Map<String, dynamic> video, AppLocalizations l10n) {
    if (video['hasFinalVideo'] != true) {
      AppNotice.show(context, l10n.libraryVideoNotReady, type: NoticeType.info);
      return;
    }
    openClipPlayer(
      context,
      title: video['songTitle']?.toString() ?? '',
      projectId: video['projectId'].toString(),
      videoService: widget.videoService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.songLibrary, widget.player]),
        builder: (context, _) {
          final entries = _entries();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.navLibrary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    AccountHeaderActions(
                      library: widget.songLibrary,
                      authService: widget.authService,
                      service: widget.service,
                      onOpenSettings: widget.onOpenSettings,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FilterBar(
                selected: _filter,
                labels: {
                  LibraryFilter.all: l10n.libraryFilterAll,
                  LibraryFilter.music: l10n.libraryFilterMusic,
                  LibraryFilter.video: l10n.libraryFilterVideo,
                  LibraryFilter.remix: l10n.libraryFilterRemix,
                },
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.pink,
                  backgroundColor: AppColors.surfaceElevated,
                  onRefresh: _refresh,
                  child: entries.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text(
                                _filter == LibraryFilter.all
                                    ? l10n.libraryEmptyAll
                                    : l10n.libraryEmptyFiltered,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 4, bottom: 24),
                          itemCount: entries.length,
                          itemBuilder: (context, i) =>
                              _buildEntry(context, l10n, entries[i]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEntry(
    BuildContext context,
    AppLocalizations l10n,
    _Entry entry,
  ) {
    final song = entry.song;
    if (song != null) {
      if (song.pendingId != null) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
          child: GenerationCard(
            key: ValueKey(song.pendingId),
            librarySong: song,
            onDismiss: song.isFailedGeneration
                ? () => widget.songLibrary.removePending(song)
                : null,
          ),
        );
      }
      final remix = _isRemix(song);
      return LibraryListItem(
        key: ValueKey('song-${song.song.id}'),
        title: song.song.title,
        imageUrl: song.song.imageUrl,
        kind: remix ? LibraryItemKind.remix : LibraryItemKind.music,
        kindLabel: remix ? l10n.libraryFilterRemix : l10n.libraryFilterMusic,
        metadata: _join([_formatDate(context, song.createdAt), song.genre]),
        isPlaying:
            widget.player.current?.song.id == song.song.id &&
            widget.player.isPlaying,
        onTap: () => _playSong(song),
        onMore: () => _showSongActions(context, song),
      );
    }

    final video = entry.video!;
    final status = video['status']?.toString() ?? '';
    final ready = video['hasFinalVideo'] == true;
    final failed = status.endsWith('_failed');
    final songId = video['songId']?.toString();
    final sourceSong = songId == null
        ? null
        : widget.songLibrary.songs
              .where((s) => s.song.id == songId)
              .firstOrNull;

    return LibraryListItem(
      key: ValueKey('video-${video['projectId']}'),
      title: video['songTitle']?.toString() ?? '',
      imageUrl: sourceSong?.song.imageUrl ?? '',
      kind: LibraryItemKind.video,
      kindLabel: l10n.libraryFilterVideo,
      metadata: _join([
        _formatDate(context, entry.createdAt),
        if (failed)
          l10n.libraryVideoFailed
        else if (!ready)
          l10n.libraryVideoInProgress
        else
          sourceSong?.genre ?? '',
      ]),
      isDimmed: !ready,
      onTap: () => _openVideo(video, l10n),
      onMore: () => _showVideoActions(context, video, l10n),
    );
  }

  void _showSongActions(BuildContext context, LibrarySong song) {
    final l10n = AppLocalizations.of(context)!;
    _showSheet(context, [
      _SheetAction(
        icon: song.isFavorite ? Icons.favorite : Icons.favorite_border,
        iconColor: AppColors.pink,
        label: song.isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
        onTap: () => widget.songLibrary.toggleFavorite(song),
      ),
      _SheetAction(
        icon: Icons.edit_outlined,
        label: l10n.actionRename,
        onTap: () => _showRenameDialog(context, song),
      ),
      _SheetAction(
        icon: Icons.share_outlined,
        label: l10n.actionShare,
        onTap: () => AppNotice.show(
          context,
          l10n.shareComingSoonMessage,
          type: NoticeType.warning,
        ),
      ),
      _SheetAction(
        icon: Icons.download_outlined,
        label: l10n.actionDownload,
        onTap: () => AppNotice.show(
          context,
          l10n.downloadComingSoonMessage,
          type: NoticeType.warning,
        ),
      ),
      _SheetAction(
        icon: Icons.delete_outline,
        label: l10n.actionDelete,
        destructive: true,
        onTap: () async {
          try {
            await widget.songLibrary.remove(song);
          } on SunoApiException catch (e) {
            if (context.mounted) {
              AppNotice.show(context, e.message, type: NoticeType.error);
            }
          }
        },
      ),
    ]);
  }

  void _showVideoActions(
    BuildContext context,
    Map<String, dynamic> video,
    AppLocalizations l10n,
  ) {
    _showSheet(context, [
      _SheetAction(
        icon: Icons.delete_outline,
        label: l10n.actionDelete,
        destructive: true,
        onTap: () => _confirmDeleteVideo(context, video, l10n),
      ),
    ]);
  }

  Future<void> _confirmDeleteVideo(
    BuildContext context,
    Map<String, dynamic> video,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(
          l10n.libraryDeleteVideoTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.libraryDeleteVideoMessage(video['songTitle']?.toString() ?? ''),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.actionDelete,
              style: const TextStyle(color: AppColors.pink),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.videoService.deleteProject(video['projectId'].toString());
      await _loadVideos();
    } on MusicVideoException catch (e) {
      if (context.mounted) {
        AppNotice.show(context, e.message, type: NoticeType.error);
      }
    }
  }

  void _showRenameDialog(BuildContext context, LibrarySong song) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: song.song.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(
          l10n.renameSongTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              widget.songLibrary.rename(song, controller.text.trim());
              Navigator.pop(context);
            },
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showSheet(BuildContext context, List<_SheetAction> actions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final a in actions)
              ListTile(
                leading: Icon(
                  a.icon,
                  color: a.destructive
                      ? Colors.red
                      : (a.iconColor ?? AppColors.textSecondary),
                ),
                title: Text(
                  a.label,
                  style: TextStyle(
                    color: a.destructive ? Colors.red : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  a.onTap();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetAction {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool destructive;
}

/// Tümü / Müzik / Video / Remix filtre çipleri. Seçili çip Melodia
/// gradyanıyla dolu, diğerleri ince çerçeveli.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.labels,
    required this.onChanged,
  });

  final LibraryFilter selected;
  final Map<LibraryFilter, String> labels;
  final ValueChanged<LibraryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final f in LibraryFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: labels[f] ?? '',
                selected: f == selected,
                onTap: () => onChanged(f),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.pink.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
