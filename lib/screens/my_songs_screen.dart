import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/generation_card.dart';
import '../widgets/song_tile.dart';

class MySongsScreen extends StatefulWidget {
  const MySongsScreen({
    super.key,
    required this.library,
    required this.player,
    this.initialFavoritesOnly = false,
  });

  final SongLibrary library;
  final PlayerController player;

  /// "Favorilerim" kartından açıldığında true geçirilir; ekran doğrudan
  /// favori filtresi açık şekilde başlar.
  final bool initialFavoritesOnly;

  @override
  State<MySongsScreen> createState() => _MySongsScreenState();
}

class _MySongsScreenState extends State<MySongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late bool _favoritesOnly = widget.initialFavoritesOnly;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // DÜZELTME: Önceden bu ekran çıplak bir SafeArea döndürüyordu ve
    // library_screen.dart onu ayrı bir Scaffold+standart AppBar içine
    // sarıyordu. AppBar'ın arka planı (tema varsayılanı, düz siyah) ile
    // hemen altındaki backgroundGlow gradyanının üst rengi (mora çalan)
    // arasında görünür bir sınır/renk sıçraması oluyordu. Artık Videolarım
    // ekranıyla (video_library_screen.dart) BİREBİR aynı desen: ekran
    // kendi Scaffold'unu ve gradyanını yönetiyor, gradyan en tepeden
    // (durum çubuğunun hemen altından) başlıyor, standart AppBar yok.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([widget.library, widget.player]),
            builder: (context, _) {
              var songs = widget.library.songs;
              // DEĞİŞTİ: Devam eden üretim kartları (generation card)
              // favori/arama filtrelerinden ETKİLENMEZ -- kullanıcı
              // hangi filtrede olursa olsun üretimini takip edebilmeli.
              if (_favoritesOnly) {
                songs = songs
                    .where((s) => s.isFavorite || s.pendingId != null)
                    .toList();
              }
              if (_query.isNotEmpty) {
                songs = songs
                    .where(
                      (s) =>
                          s.pendingId != null ||
                          s.song.title
                              .toLowerCase()
                              .contains(_query.toLowerCase()),
                    )
                    .toList();
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.librarySongsTitle,
                          style: const TextStyle(
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
                      decoration: InputDecoration(
                        hintText: l10n.searchSongsHint,
                        prefixIcon: const Icon(
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
                    ? Center(
                        child: Text(
                          l10n.noSongsFound,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final s = songs[index];
                          // YENİ: Devam eden (ya da başarısız olmuş) bir
                          // üretim için normal SongTile yerine
                          // GenerationCard gösterilir -- ayrı bir
                          // loading sayfası YOK, kart doğrudan bu
                          // listenin içinde. Aynı pendingId için asla
                          // ikinci bir kart oluşmaz (bkz. SongLibrary).
                          if (s.pendingId != null) {
                            return GenerationCard(
                              key: ValueKey(s.pendingId),
                              librarySong: s,
                              onDismiss: s.isFailedGeneration
                                  ? () => widget.library.removePending(s)
                                  : null,
                            );
                          }
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
        ),
      ),
    );
  }

  void _showActions(BuildContext context, LibrarySong song) {
    final l10n = AppLocalizations.of(context)!;
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
                      ? l10n.removeFromFavorites
                      : l10n.addToFavorites,
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
                title: Text(
                  l10n.actionRename,
                  style: const TextStyle(color: AppColors.textPrimary),
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
                title: Text(
                  l10n.actionShare,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.shareComingSoonMessage)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.download_outlined,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  l10n.actionDownload,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.downloadComingSoonMessage)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  l10n.actionDelete,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  // DEĞİŞTİ: remove() artık backend'e gerçekten silme
                  // isteği gönderiyor (Future<void>) -- başarısız olursa
                  // kullanıcıya bir mesaj gösteriyoruz, şarkı listeye
                  // otomatik geri eklenir (bkz. SongLibrary.remove).
                  Navigator.pop(context);
                  try {
                    await widget.library.remove(song);
                  } on SunoApiException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
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
              widget.library.rename(song, controller.text.trim());
              Navigator.pop(context);
            },
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }
}