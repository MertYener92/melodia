import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:melodia/l10n/generated/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/aligned_word.dart';
import '../models/song.dart';
import '../services/music_video_service.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notice.dart';
import '../widgets/karaoke_lyrics_view.dart';
import '../widgets/player/playback_controls.dart';
import '../widgets/player/player_progress_bar.dart';
import '../widgets/player/player_shared.dart';
import '../widgets/player/remix_sheet.dart';
import 'select_video_package_screen.dart';

/// Tam ekran "Now Playing" ekranı. Mini player ile aynı controller'ı
/// dinler; kapak görseli mini player'dan Hero ile büyüyerek gelir.
///
/// Dikey hiyerarşi: başlık çubuğu -> büyük kapak -> başlık/alt başlık +
/// favori -> aksiyon pill'leri -> ilerleme çubuğu -> oynatma kontrolleri.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.controller,
    required this.library,
    required this.service,
    required this.musicVideoService,
    this.onOpenLibrary,
    this.onBuyCredits,
  });

  final PlayerController controller;

  /// Remix başlayınca "Görüntüle" -> player'ı kapatıp Kütüphane sekmesine.
  final VoidCallback? onOpenLibrary;

  /// Remix için jeton yetmiyorsa "Kredi al" -> jeton paketi / Pro ekranı.
  final VoidCallback? onBuyCredits;

  /// Favori durumunu değiştirmek (ve güncel halini dinlemek) için.
  final SongLibrary library;
  final SunoApiService service;
  final MusicVideoService musicVideoService;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const double _hPad = 24;

  /// İndirme/paylaşma sırasında ses dosyası indiriliyor mu.
  bool _busy = false;

  PlayerController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: Listenable.merge([_controller, widget.library]),
        builder: (context, _) {
          final librarySong = _controller.current;
          if (librarySong == null) return _buildEmpty(l10n);

          return Stack(
            children: [
              const _GraniteBackdrop(),
              SafeArea(
                child: GestureDetector(
                  // Aşağı kaydırınca küçült (mini player'a dön).
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) > 400) {
                      Navigator.of(context).maybePop();
                    }
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        _buildContent(context, constraints, librarySong, l10n),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return SafeArea(
      child: Column(
        children: [
          _Header(
            onMinimize: () => Navigator.of(context).maybePop(),
            onMore: null,
          ),
          Expanded(
            child: Center(
              child: Text(
                l10n.playerNoSong,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BoxConstraints constraints,
    LibrarySong librarySong,
    AppLocalizations l10n,
  ) {
    final song = librarySong.song;
    final error = _controller.error;

    // Kapak: genişliğe göre responsive, ama geri kalan her şeye (başlık,
    // aksiyonlar, ilerleme, kontroller ≈ 400px) yer kalacak şekilde
    // yüksekliğe göre de sınırlı -- küçük ekranlarda ezilmez, büyük
    // ekranlarda da devasa olmaz.
    final maxByWidth = constraints.maxWidth - _hPad * 2;
    final maxByHeight = constraints.maxHeight - 400;
    final artSize = math.min(maxByWidth, maxByHeight).clamp(150.0, 400.0);

    return Column(
      children: [
        _Header(
          onMinimize: () => Navigator.of(context).maybePop(),
          onMore: () => _openMoreSheet(librarySong, l10n),
        ),
        const Spacer(),
        SongArtwork(
          imageUrl: song.imageUrl,
          size: artSize,
          radius: 16,
          heroTag: kPlayerArtworkHeroTag,
        ),
        const Spacer(),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error ?? playerSubtitle(librarySong, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: error != null
                            ? AppColors.pink
                            : AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => widget.library.toggleFavorite(librarySong),
                tooltip: librarySong.isFavorite
                    ? l10n.playerRemoveFavorite
                    : l10n.playerAddFavorite,
                iconSize: 24,
                color: librarySong.isFavorite
                    ? AppColors.pink
                    : AppColors.textSecondary,
                icon: Icon(
                  librarySong.isFavorite
                      ? PlayerIcons.favorite
                      : PlayerIcons.favoriteOutline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ActionRow(
          horizontalPadding: _hPad,
          shareBusy: _busy,
          onRemix: () => _openRemixSheet(librarySong),
          onShare: () => _onShareTap(song),
          onPlaylist: () => _showComingSoon(l10n),
          onComment: () => _showComingSoon(l10n),
        ),
        const SizedBox(height: 22),
        Padding(
          // Slider kendi içinde ~14px yatay boşluk bıraktığı için biraz az.
          padding: const EdgeInsets.symmetric(horizontal: _hPad - 12),
          child: PlayerProgressBar(
            position: _controller.position,
            duration: _controller.duration,
            onSeek: _controller.seek,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad - 8),
          child: PlaybackControls(controller: _controller),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --------------------------------------------------------------------
  // Aksiyonlar -- indirme/paylaşma mantığı önceki _PlayerActionsRow ile
  // AYNI (taze CloudFront signed URL -> geçici dosya -> native share).
  // --------------------------------------------------------------------

  String _safeFileName(Song song) {
    final cleaned = song.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    return (cleaned.isEmpty ? 'melodia-song' : cleaned).replaceAll(' ', '_');
  }

  /// Ses dosyasını indirip geçici bir klasöre kaydeder, yerel dosya
  /// yolunu döner. İndirme ve paylaşma aynı temel işlemi kullanır.
  Future<File?> _downloadAudioFile(Song song) async {
    setState(() => _busy = true);
    try {
      final audioUrl = await widget.service.resolvePlayUrl(song);

      final response = await http
          .get(Uri.parse(audioUrl))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        _showMessage('Dosya indirilemedi (${response.statusCode}).');
        return null;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_safeFileName(song)}.mp3');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } on SunoApiException catch (e) {
      _showMessage(e.message);
      return null;
    } catch (e) {
      _showMessage('İndirme sırasında bir hata oluştu.');
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onDownloadTap(Song song) async {
    if (_busy) return;
    final file = await _downloadAudioFile(song);
    if (file == null || !mounted) return;

    // Flutter'da uygulamalar arası "indirilenler" klasörüne doğrudan
    // yazma izni gerektirmeden en güvenilir yol: native paylaşım
    // sayfasını açmak. Kullanıcı buradan "Dosyalara Kaydet" / "Save to
    // Files" ile cihazına kalıcı olarak kaydedebilir.
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: song.title),
    );
  }

  Future<void> _onShareTap(Song song) async {
    if (_busy) return;
    final file = await _downloadAudioFile(song);
    if (file == null || !mounted) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '${song.title} — Melodia ile AI ile üretildi 🎵',
      ),
    );
  }

  void _openCreateVideo(LibrarySong librarySong) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectVideoPackageScreen(
          videoService: widget.musicVideoService,
          service: widget.service,
          song: librarySong.song,
          genre: librarySong.genre,
          mood: librarySong.mood,
        ),
      ),
    );
  }

  void _openLyricsSheet(Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LyricsSheet(
        song: song,
        controller: _controller,
        service: widget.service,
      ),
    );
  }

  /// Remix paneli: tarz seçilir, gönderilince panel kapanır ve üretim
  /// arka planda (normal üretimle aynı kütüphane kartlarıyla) başlar.
  void _openRemixSheet(LibrarySong source) {
    final remaining = widget.library.remainingCredits;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => RemixSheet(
        source: source,
        availableCredits: remaining == null
            ? null
            : remaining + widget.library.bonusCredits,
        onBuyCredits: widget.onBuyCredits == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                widget.onBuyCredits!();
              },
        onSubmit: (request) {
          Navigator.of(sheetContext).pop();
          _startRemix(source, request);
        },
      ),
    );
  }

  Future<void> _startRemix(LibrarySong source, RemixRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    // Kök ScaffoldMessenger: kullanıcı player'ı kapatsa bile sonuç mesajı
    // o an açık olan ekranda görünür.
    final messenger = ScaffoldMessenger.of(context);
    final controller = _controller;
    AppNotice.showOn(
      messenger,
      l10n.remixStartedDetail,
      type: NoticeType.progress,
      title: l10n.remixStarted,
      actionLabel: widget.onOpenLibrary == null ? null : l10n.remixView,
      onAction: widget.onOpenLibrary,
    );

    final created = await widget.library.startRemix(
      source: source,
      style: request.style,
      styleLabel: request.styleLabel,
      instrumental: request.instrumental,
    );

    if (created.isEmpty) {
      AppNotice.showOn(
        messenger,
        l10n.remixFailedDetail,
        type: NoticeType.error,
        title: l10n.remixFailed,
      );
    } else {
      AppNotice.showOn(
        messenger,
        created.first.song.title,
        type: NoticeType.success,
        title: l10n.remixReady,
        actionLabel: l10n.remixListen,
        onAction: () => controller.playSong(created.first),
      );
    }
  }

  // TODO(playlist/comment): Uygulamada henüz çalma listesi ve yorum sistemi
  // YOK (backend'de de uç nokta yok). Butonlar tasarım gereği yerinde
  // duruyor; sahte bir işlem yapmak yerine "Yakında" gösteriliyor.
  void _showComingSoon(AppLocalizations l10n) =>
      _showMessage(l10n.playerComingSoon, type: NoticeType.warning);

  void _showMessage(String message, {NoticeType type = NoticeType.error}) {
    if (!mounted) return;
    AppNotice.show(context, message, type: type);
  }

  /// Üç nokta menüsü: şarkıya ait mevcut tüm aksiyonlar.
  void _openMoreSheet(LibrarySong librarySong, AppLocalizations l10n) {
    final song = librarySong.song;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // Varsayılan 9/16 yükseklik sınırı son satırı kesiyordu; içerik
      // kadar yükseklik alsın.
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        void run(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        return _MoreSheet(
          librarySong: librarySong,
          subtitle: playerSubtitle(librarySong, l10n),
          items: [
            _MoreItem(
              icon: librarySong.isFavorite
                  ? PlayerIcons.favorite
                  : PlayerIcons.favoriteOutline,
              label: librarySong.isFavorite
                  ? l10n.playerRemoveFavorite
                  : l10n.playerAddFavorite,
              highlighted: librarySong.isFavorite,
              onTap: () =>
                  run(() => widget.library.toggleFavorite(librarySong)),
            ),
            _MoreItem(
              icon: PlayerIcons.download,
              label: l10n.playerDownload,
              onTap: () => run(() => _onDownloadTap(song)),
            ),
            _MoreItem(
              icon: PlayerIcons.share,
              label: l10n.playerShare,
              onTap: () => run(() => _onShareTap(song)),
            ),
            _MoreItem(
              icon: PlayerIcons.lyrics,
              label: l10n.playerLyrics,
              onTap: () => run(() => _openLyricsSheet(song)),
            ),
            _MoreItem(
              icon: PlayerIcons.video,
              label: l10n.playerCreateVideo,
              onTap: () => run(() => _openCreateVideo(librarySong)),
            ),
          ],
        );
      },
    );
  }
}

/// DEĞİŞTİ: Tam ekran player'ın arka planı artık kapaktan üretilen bulanık
/// görsel değil, uygulamanın kütüphane ekranlarıyla AYNI granit gradyanı
/// (AppColors.libraryGranite) + üstte hafif bir mor ışıma -- player
/// uygulamanın geri kalanıyla aynı renk dünyasında duruyor.
class _GraniteBackdrop extends StatelessWidget {
  const _GraniteBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.libraryGranite),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.75),
                radius: 1.1,
                colors: [
                  AppColors.purple.withValues(alpha: 0.16),
                  AppColors.purple.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMinimize, required this.onMore});

  final VoidCallback onMinimize;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            IconButton(
              onPressed: onMinimize,
              tooltip: l10n.playerMinimize,
              iconSize: 30,
              color: Colors.white,
              icon: const Icon(PlayerIcons.minimize),
            ),
            const Spacer(),
            if (onMore != null)
              IconButton(
                onPressed: onMore,
                tooltip: l10n.playerMoreActions,
                iconSize: 26,
                color: Colors.white,
                icon: const Icon(PlayerIcons.more),
              ),
          ],
        ),
      ),
    );
  }
}

/// Remix · Paylaş · Çalma listesi · Yorum. Küçük ekranlarda yatay kayar.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.horizontalPadding,
    required this.shareBusy,
    required this.onRemix,
    required this.onShare,
    required this.onPlaylist,
    required this.onComment,
  });

  final double horizontalPadding;
  final bool shareBusy;
  final VoidCallback onRemix;
  final VoidCallback onShare;
  final VoidCallback onPlaylist;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        children: [
          _ActionPill(
            icon: PlayerIcons.remix,
            label: l10n.playerRemix,
            onTap: onRemix,
          ),
          const SizedBox(width: 8),
          _ActionPill(
            icon: PlayerIcons.share,
            label: l10n.playerShare,
            busy: shareBusy,
            onTap: onShare,
          ),
          const SizedBox(width: 8),
          _ActionPill(
            icon: PlayerIcons.playlist,
            label: l10n.playerPlaylist,
            onTap: onPlaylist,
          ),
          const SizedBox(width: 8),
          _ActionPill(
            icon: PlayerIcons.comment,
            label: l10n.playerComment,
            onTap: onComment,
          ),
        ],
      ),
    );
  }
}

/// Kompakt, koyu yüzeyli, ince çerçeveli aksiyon butonu.
class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: AppColors.textPrimary,
                  ),
                )
              else
                Icon(icon, size: 17, color: AppColors.textPrimary),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;
}

class _MoreSheet extends StatelessWidget {
  const _MoreSheet({
    required this.librarySong,
    required this.subtitle,
    required this.items,
  });

  final LibrarySong librarySong;
  final String subtitle;
  final List<_MoreItem> items;

  @override
  Widget build(BuildContext context) {
    final song = librarySong.song;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    SongArtwork(imageUrl: song.imageUrl, size: 44, radius: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 6),
              for (final item in items)
                ListTile(
                  onTap: item.onTap,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  minLeadingWidth: 24,
                  leading: Icon(
                    item.icon,
                    size: 22,
                    color: item.highlighted
                        ? AppColors.pink
                        : AppColors.textPrimary,
                  ),
                  title: Text(
                    item.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alttan açılan, karaoke sözlerini gösteren panel. Şarkının [taskId]'si
/// yoksa (örn. çok eski bir kayıt) bunu kullanıcıya açıkça belirtir.
class _LyricsSheet extends StatefulWidget {
  const _LyricsSheet({
    required this.song,
    required this.controller,
    required this.service,
  });

  final Song song;
  final PlayerController controller;
  final SunoApiService service;

  @override
  State<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<_LyricsSheet> {
  late final Future<List<AlignedWord>> _future = _load();

  /// DÜZELTME: Karaoke zaman-damgalı sözler backend'de SADECE Suno için
  /// var (lyricsTimestamps.js -> Suno'nun /get-timestamped-lyrics API'si)
  /// -- Lyria (Google) için eşdeğer bir API bu uygulamaya entegre değil.
  /// Önceden bu kontrol yapılmıyordu, Lyria şarkıları için de Suno'ya
  /// özel bu isteği atıp (başarısız olup) genel/yanıltıcı bir "henüz
  /// mevcut değil" mesajı gösteriyordu. Artık Lyria şarkıları için
  /// GEREKSİZ AĞ İSTEĞİ ATILMIYOR, kullanıcıya net bir sebep gösteriliyor.
  bool get _isUnsupportedProvider =>
      widget.song.provider.toLowerCase() == 'lyria';

  Future<List<AlignedWord>> _load() {
    if (_isUnsupportedProvider) return Future.value(const []);
    final taskId = widget.song.taskId;
    final audioId = widget.song.id;
    if (taskId.isEmpty) return Future.value(const []);
    return widget.service.fetchTimestampedLyrics(
      taskId: taskId,
      audioId: audioId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.playerLyrics,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<AlignedWord>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.pink),
                      );
                    }

                    final words = snapshot.data ?? const [];
                    if (words.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _isUnsupportedProvider
                                ? 'Lyria ile üretilen şarkılar için karaoke sözleri şu an desteklenmiyor.'
                                : 'Bu şarkı için karaoke sözleri henüz mevcut değil.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }

                    // Canlı çalma pozisyonunu takip etmek için controller'ı
                    // dinliyoruz; kelime vurgusu ve otomatik kaydırma bu
                    // sayede anlık güncellenir.
                    return ListenableBuilder(
                      listenable: widget.controller,
                      builder: (context, _) {
                        return KaraokeLyricsView(
                          words: words,
                          position: widget.controller.position,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
