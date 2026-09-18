import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/generation_card.dart';
import '../widgets/library_mode_filter.dart';
import '../widgets/screen_header.dart';
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
  // DEĞİŞTİ: Metin tabanlı arama kutusu KALDIRILDI -- yerine referans
  // tasarımdaki gibi yatay kaydırılabilir mod filtresi (Tümü/Hızlı/
  // Standart/Gelişmiş) geldi. Bkz. widgets/library_mode_filter.dart.
  LibraryFilterMode _selectedMode = LibraryFilterMode.all;

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
    //
    // DEĞİŞTİ: backgroundGlow yerine libraryGranite -- tepeden aşağı
    // çok katmanlı, granit dokulu gradyan (bkz. theme/app_theme.dart).
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.libraryGranite),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([widget.library, widget.player]),
            builder: (context, _) {
              var songs = widget.library.songs;
              // DEĞİŞTİ: Favori-sadece filtresi (kalp butonu) KOMPLE
              // KALDIRILDI -- artık sadece mod filtresi var. Devam eden
              // üretim kartları (generation card) mod filtresinden
              // ETKİLENMEZ -- kullanıcı hangi filtrede olursa olsun
              // üretimini takip edebilmeli.
              if (_selectedMode.value != null) {
                songs = songs
                    .where(
                      (s) => s.pendingId != null || _selectedMode.matches(s.mode),
                    )
                    .toList();
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: ScreenHeader(title: l10n.librarySongsTitle),
                  ),
                  LibraryModeFilter(
                    selected: _selectedMode,
                    onChanged: (mode) => setState(() => _selectedMode = mode),
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
                                onToggleFavorite: () => widget.library.toggleFavorite(s),
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