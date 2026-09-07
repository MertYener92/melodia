import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/music_video_service.dart';
import '../theme/app_theme.dart';

/// "Kütüphane" sekmesi: kullanıcının ürettiği tüm AI müzik klipleri
/// (video projeleri) burada listelenir. Eski "Discover" (sahte/örnek
/// topluluk verisi gösteren) ekranının yerine geçti.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.videoService});

  final MusicVideoService videoService;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<Map<String, dynamic>>> _future = widget.videoService.fetchProjects();

  Future<void> _refresh() async {
    setState(() => _future = widget.videoService.fetchProjects());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const Text(
                  'Kütüphane',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
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
                  ...projects.map((p) => _LibraryTile(project: p)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({required this.project});

  final Map<String, dynamic> project;

  @override
  Widget build(BuildContext context) {
    final status = project['status']?.toString() ?? '';
    final finalVideoUrl = project['finalVideoUrl']?.toString();
    final isReady = finalVideoUrl != null && finalVideoUrl.isNotEmpty;
    final title = project['songTitle']?.toString() ?? 'Adsız Şarkı';
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
                    builder: (_) => _ClipPlayerScreen(title: title, videoUrl: finalVideoUrl),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ClipPlayerScreen extends StatefulWidget {
  const _ClipPlayerScreen({required this.title, required this.videoUrl});

  final String title;
  final String videoUrl;

  @override
  State<_ClipPlayerScreen> createState() => _ClipPlayerScreenState();
}

class _ClipPlayerScreenState extends State<_ClipPlayerScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await controller.initialize();
    await controller.play();
    if (mounted) setState(() => _controller = controller);
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
          child: _controller == null
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