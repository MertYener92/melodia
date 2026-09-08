import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/music_video_service.dart';
import '../theme/app_theme.dart';

/// "Kütüphane" sekmesi: kullanıcının ürettiği tüm AI müzik klipleri
/// (video projeleri) burada listelenir. Eski "Discover" (sahte/örnek
/// topluluk verisi gösteren) ekranının yerine geçti.
class VideoLibraryScreen extends StatefulWidget {
  const VideoLibraryScreen({super.key, required this.videoService});

  final MusicVideoService videoService;

  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  late Future<List<Map<String, dynamic>>> _future = widget.videoService.fetchProjects();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Videolarım')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          top: false,
          child: _buildContent(),
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

            final projects = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'Oluşturduğun AI müzik klipleri',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
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
                        const Text(
                          'Henüz klip oluşturmadın',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bir şarkı aç, oynatıcıdaki klip ikonuna bas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  )
                else
                  ...projects.map((p) => _LibraryTile(
                        project: p,
                        videoService: widget.videoService,
                        onDelete: () => _confirmDelete(context, p),
                      )),
              ],
            );
          },
        ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.project,
    required this.videoService,
    required this.onDelete,
  });

  final Map<String, dynamic> project;
  final MusicVideoService videoService;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = project['status']?.toString() ?? '';
    // DEĞİŞTİ: backend artık "finalVideoUrl" değil, "hasFinalVideo"
    // (bool) döndürüyor -- gerçek oynatma linki artık burada değil,
    // oynatma anında ayrıca çekiliyor (bkz. _ClipPlayerScreen).
    final isReady = project['hasFinalVideo'] == true;
    final projectId = project['projectId']?.toString() ?? '';
    final title = project['songTitle']?.toString() ?? 'Adsız klip';
    final cost = (project['estimatedCostUsd'] as num?)?.toDouble() ?? 0;

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
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
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppColors.glassCard(),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isReady ? AppColors.primaryGradient : null,
                  color: isReady ? null : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isReady ? Icons.play_arrow_rounded : Icons.hourglass_top_rounded,
                  color: isReady ? Colors.white : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${cost.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // DEĞİŞTİ: URL artık widget'a doğrudan geçirilmiyor. Ekran her
      // açıldığında taze bir CloudFront signed URL isteniyor -- bu,
      // eski sistemdeki "linkin süresi dolmuş" sorununu ortadan
      // kaldırıyor, çünkü link hep bu anda, yeni üretiliyor.
      final playUrl = await widget.videoService.getVideoPlayUrl(widget.projectId);
      final controller = VideoPlayerController.networkUrl(Uri.parse(playUrl));
      await controller.initialize();
      await controller.play();
      if (mounted) setState(() => _controller = controller);
    } on MusicVideoException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Video açılamadı.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: Center(
          child: _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : _controller == null
                  ? const CircularProgressIndicator(color: AppColors.pink)
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                        });
                      },
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
        ),
      ),
    );
  }
}