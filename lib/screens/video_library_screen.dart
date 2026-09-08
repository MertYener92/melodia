import 'dart:async';
import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../services/music_video_service.dart';
import '../theme/app_theme.dart';

/// Başka ekranlardan (örn. Favorilerim) da tam ekran klip oynatıcıyı
/// açabilmek için dışarıya açık yardımcı fonksiyon.
void openClipPlayer(
  BuildContext context, {
  required String title,
  required String projectId,
  required MusicVideoService videoService,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _ClipPlayerScreen(
        title: title,
        projectId: projectId,
        videoService: videoService,
      ),
    ),
  );
}

/// "Kütüphane" sekmesi: kullanıcının ürettiği tüm AI müzik klipleri
/// (video projeleri) burada listelenir.
class VideoLibraryScreen extends StatefulWidget {
  const VideoLibraryScreen({super.key, required this.videoService});

  final MusicVideoService videoService;

  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  late Future<List<Map<String, dynamic>>> _future = widget.videoService.fetchProjects();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.videoService.fetchProjects());
    await _future;
  }

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> project) async {
    final title = project['songTitle']?.toString() ?? 'Bu klip';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Klibi sil', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '"$title" kalıcı olarak silinecek. Bu işlem geri alınamaz.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil', style: TextStyle(color: AppColors.pink)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final projectId = project['projectId'].toString();
      await widget.videoService.deleteProject(projectId);
      await _refresh();
    } on MusicVideoException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _showActions(BuildContext context, Map<String, dynamic> project) {
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
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, project);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // DEĞİŞTİ: Standart AppBar yerine, Şarkılarım (My Songs) ekranıyla
      // aynı görsel dil -- büyük kalın başlık + arama kutusu. Geri
      // dönme oku ayrı bir satırda korunuyor.
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    ),
                    const Text(
                      'Videolarım',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                    hintText: 'Search videos...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
        color: AppColors.pink,
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.pink),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.error_outline, color: AppColors.pink, size: 32),
                  SizedBox(height: 12),
                  Text(
                    'Klipler yüklenemedi. Aşağı çekip tekrar dene.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              );
            }

            var projects = snapshot.data ?? [];
            // YENİ: başlığa göre arama filtresi -- Şarkılarım'daki gibi.
            if (_query.isNotEmpty) {
              projects = projects
                  .where((p) => (p['songTitle']?.toString() ?? '')
                      .toLowerCase()
                      .contains(_query.toLowerCase()))
                  .toList();
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                if (projects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.video_library_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _query.isNotEmpty ? 'No videos found' : 'Henüz klip oluşturmadın',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                        if (_query.isEmpty) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Bir şarkı aç, oynatıcıdaki klip ikonuna bas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  ...projects.map((p) => _LibraryTile(
                        project: p,
                        videoService: widget.videoService,
                        onMore: () => _showActions(context, p),
                      )),
              ],
            );
          },
        ),
    );
  }
}

/// Görsel kutu + kalın başlık + soluk alt yazı (durum) + tek "..." menüsü
/// -- song_tile.dart ile aynı görsel dil.
class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.project,
    required this.videoService,
    required this.onMore,
  });

  final Map<String, dynamic> project;
  final MusicVideoService videoService;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final status = project['status']?.toString() ?? '';
    final isReady = project['hasFinalVideo'] == true;
    final projectId = project['projectId']?.toString() ?? '';
    final title = project['songTitle']?.toString() ?? 'Adsız klip';

    String statusLabel;
    Color statusColor;
    switch (status) {
      case 'completed':
        statusLabel = 'Hazır';
        statusColor = Colors.greenAccent;
      case 'assembling':
        statusLabel = 'Birleştiriliyor...';
        statusColor = AppColors.textMuted;
      case 'generating':
        statusLabel = 'Sahneler üretiliyor...';
        statusColor = AppColors.textMuted;
      case 'assembly_failed':
      case 'scenes_failed':
        statusLabel = 'Başarısız oldu';
        statusColor = AppColors.pink;
      default:
        statusLabel = status;
        statusColor = AppColors.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppColors.glassCard(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isReady
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ClipPlayerScreen(
                        title: title,
                        projectId: projectId,
                        videoService: videoService,
                      ),
                    ),
                  )
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tam ekran klip sayfası. DEĞİŞTİ: Elle yazılan oynatma/duraklat/sarma
/// mantığı kaldırıldı, yerine `chewie` paketi kondu -- milyonlarca
/// uygulamada kullanılan, test edilmiş, güvenilir bir video oynatıcı
/// kütüphanesi (play/pause, seek bar, tam ekran, buffering göstergesi
/// hepsi hazır ve garanti çalışıyor).
class _ClipPlayerScreen extends StatefulWidget {
  const _ClipPlayerScreen({
    required this.title,
    required this.projectId,
    required this.videoService,
  });

  final String title;
  final String projectId;
  final MusicVideoService videoService;

  @override
  State<_ClipPlayerScreen> createState() => _ClipPlayerScreenState();
}

class _ClipPlayerScreenState extends State<_ClipPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _error;
  bool _busy = false;
  String? _concept;
  bool _isFavorite = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // YENİ: Video konsept/içerik bilgisini de çekiyoruz (paylaş
      // butonunun eski yerinde gösterilecek).
      final playUrlFuture = widget.videoService.getVideoPlayUrl(widget.projectId);
      final projectFuture = widget.videoService.getStatus(widget.projectId);

      final playUrl = await playUrlFuture;
      final videoController = VideoPlayerController.networkUrl(Uri.parse(playUrl));
      await videoController.initialize();

      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        // DEĞİŞTİ: Chewie'nin varsayılan kontrolleri yerine kendi
        // kontrol çubuğumuz -- küçük ekranda kompakt butonlar + geniş/
        // aşağıda ilerleme çubuğu, tam ekranda normal boyutlar.
        customControls: _ChewieCustomControls(),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.pink,
          handleColor: Colors.white,
          bufferedColor: Colors.white30,
          backgroundColor: Colors.white12,
        ),
      );

      String? concept;
      bool isFavorite = false;
      String? note;
      try {
        final project = await projectFuture;
        concept = project.concept;
        isFavorite = project.isFavorite;
        note = project.note;
      } catch (_) {
        // Konsept/favori/not bilgisi alınamazsa sessizce atla -- video
        // oynatma akışını bozmasın.
      }

      if (mounted) {
        setState(() {
          _videoController = videoController;
          _chewieController = chewieController;
          _concept = concept;
          _isFavorite = isFavorite;
          _note = note;
        });
      }
    } on MusicVideoException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Video açılamadı.');
    }
  }

  Future<void> _onShareTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await SharePlus.instance.share(
        ShareParams(text: '${widget.title} — Melodia ile AI ile üretildi 🎬'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// YENİ: Favori durumunu tersine çevirir (optimistic -- önce ekranda
  /// güncellenir, sonra backend'e gönderilir; başarısız olursa geri alınır).
  Future<void> _onFavoriteTap() async {
    final newValue = !_isFavorite;
    setState(() => _isFavorite = newValue);
    try {
      await widget.videoService.updateProject(
        projectId: widget.projectId,
        isFavorite: newValue,
      );
    } catch (_) {
      if (mounted) setState(() => _isFavorite = !newValue);
    }
  }

  /// YENİ: Klip için not ekleme/düzenleme diyaloğu.
  Future<void> _onNoteTap() async {
    final controller = TextEditingController(text: _note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Not ekle', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Bu klip hakkında bir not yaz...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _note = result);
    try {
      await widget.videoService.updateProject(projectId: widget.projectId, note: result);
    } on MusicVideoException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  /// YENİ: "..." menüsü -- klibi sil.
  Future<void> _onMoreTap() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == 'delete' && mounted) {
      try {
        await widget.videoService.deleteProject(widget.projectId);
        if (mounted) Navigator.of(context).pop();
      } on MusicVideoException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoController = _videoController;
    final chewieController = _chewieController;

    return Scaffold(
      body: Stack(
        children: [
          if (videoController != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                child: Transform.scale(scale: 1.5, child: VideoPlayer(videoController)),
              ),
            )
          else
            Positioned.fill(
              child: Container(decoration: const BoxDecoration(gradient: AppColors.backgroundGlow)),
            ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  Expanded(
                    child: _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : (chewieController == null || videoController == null)
                            ? const Center(child: CircularProgressIndicator(color: AppColors.pink))
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: AspectRatio(
                                        aspectRatio: videoController.value.aspectRatio == 0
                                            ? 9 / 16
                                            : videoController.value.aspectRatio,
                                        child: Chewie(controller: chewieController),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      widget.title,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Melodia ile AI ile oluşturuldu',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                    // YENİ: paylaş butonunun eski yerinde,
                                    // alt-metin punto boyutunda ve soluk
                                    // renkte video içeriği açıklaması.
                                    if (_concept != null && _concept!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        _concept!,
                                        // YENİ: otomatik kısaltma -- konsept
                                        // metni bazen çok uzun (AI'a verilen
                                        // tüm detaylı komut) oluyor, ekranı
                                        // taşırıyordu. 3 satırla sınırlı,
                                        // taşarsa "..." ile kesiliyor.
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12.5,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    // YENİ: Favori (kalp) + Not + Paylaş +
                                    // "..." satırı, sayı olmadan (sadece
                                    // ikonlar).
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _onFavoriteTap,
                                          icon: Icon(
                                            _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            color: _isFavorite ? AppColors.pink : AppColors.textSecondary,
                                            size: 24,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _onNoteTap,
                                          icon: Icon(
                                            _note != null && _note!.isNotEmpty
                                                ? Icons.chat_bubble_rounded
                                                : Icons.chat_bubble_outline_rounded,
                                            color: AppColors.textSecondary,
                                            size: 22,
                                          ),
                                        ),
                                        _busy
                                            ? const Padding(
                                                padding: EdgeInsets.all(12),
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pink),
                                                ),
                                              )
                                            : IconButton(
                                                onPressed: _onShareTap,
                                                icon: const Icon(Icons.share_outlined,
                                                    color: AppColors.textSecondary, size: 22),
                                              ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: _onMoreTap,
                                          icon: const Icon(Icons.more_horiz_rounded,
                                              color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chewie için özel kontrol çubuğu -- basit ve güvenilir: TEK bir
/// GestureDetector (çift dokunma YOK -- sarma zaten ayrı 10sn
/// butonlarıyla yapılıyor, bu yüzden önceki denemelerdeki
/// onTap+onDoubleTap çakışması burada söz konusu değil).
///
/// Video başladıktan/kontrollere her dokunulduğunda 2 saniye sonra
/// otomatik gizlenir (oynatılıyor olsun olmasın, fark etmez). Tekrar
/// dokununca görünür, 2 saniye sonra yine gizlenir -- hem küçük
/// ekranda hem tam ekranda aynı davranış.
class _ChewieCustomControls extends StatefulWidget {
  const _ChewieCustomControls();

  @override
  State<_ChewieCustomControls> createState() => _ChewieCustomControlsState();
}

class _ChewieCustomControlsState extends State<_ChewieCustomControls> {
  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _showControls() {
    setState(() => _visible = true);
    _scheduleHide();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = ChewieController.of(context);
    final videoController = chewieController.videoPlayerController;
    final isFullScreen = chewieController.isFullScreen;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showControls,
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: videoController,
        builder: (context, value, _) {
          final duration = value.duration;
          final position = value.position;
          final progress = duration.inMilliseconds == 0
              ? 0.0
              : position.inMilliseconds / duration.inMilliseconds;

          final sideIconSize = isFullScreen ? 38.0 : 26.0;
          final centerButtonSize = isFullScreen ? 64.0 : 44.0;
          final centerIconSize = isFullScreen ? 34.0 : 24.0;

          return IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0, 0.3, 0.55, 1],
                      ),
                    ),
                  ),

                  if (isFullScreen)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        onPressed: chewieController.exitFullScreen,
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                      ),
                    )
                  else
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        onPressed: chewieController.enterFullScreen,
                        icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                      ),
                    ),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: sideIconSize,
                          onPressed: () => videoController.seekTo(position - const Duration(seconds: 10)),
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                        ),
                        SizedBox(width: isFullScreen ? 20 : 6),
                        Container(
                          width: centerButtonSize,
                          height: centerButtonSize,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: centerIconSize,
                            onPressed: () {
                              value.isPlaying ? videoController.pause() : videoController.play();
                            },
                            icon: Icon(
                              value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: isFullScreen ? 20 : 6),
                        IconButton(
                          iconSize: sideIconSize,
                          onPressed: () => videoController.seekTo(position + const Duration(seconds: 10)),
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    left: isFullScreen ? 16 : 10,
                    right: isFullScreen ? 16 : 10,
                    bottom: isFullScreen ? 16 : 2,
                    child: Row(
                      children: [
                        Text(
                          _formatDuration(position),
                          style: const TextStyle(color: Colors.white, fontSize: 10.5),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              activeTrackColor: AppColors.pink,
                              inactiveTrackColor: Colors.white30,
                              thumbColor: Colors.white,
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              value: progress.clamp(0, 1),
                              onChanged: (v) {
                                videoController.seekTo(
                                  Duration(milliseconds: (duration.inMilliseconds * v).round()),
                                );
                              },
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(color: Colors.white, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}