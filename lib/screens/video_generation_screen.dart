import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../models/music_video_project.dart';
import '../services/music_video_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class VideoGenerationScreen extends StatefulWidget {
  const VideoGenerationScreen({
    super.key,
    required this.videoService,
    required this.initialProject,
  });

  final MusicVideoService videoService;
  final MusicVideoProject initialProject;

  @override
  State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  late MusicVideoProject _project;
  Timer? _pollTimer;
  bool _starting = false;
  bool _assembling = false;
  bool _assemblyFailed = false;
  String? _error;
  VideoPlayerController? _resultController;

  @override
  void initState() {
    super.initState();
    _project = widget.initialProject;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _resultController?.dispose();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await widget.videoService.startGeneration(_project.projectId);
      _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) => _poll());
    } on MusicVideoException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _poll() async {
    try {
      final updated = await widget.videoService.getStatus(_project.projectId);
      if (!mounted) return;
      setState(() => _project = updated);

      if (updated.allScenesDone) {
        _pollTimer?.cancel();
        _pollTimer = null;
        if (updated.completedSceneCount > 0) {
          _assemble();
        } else {
          setState(() => _error = 'Hiçbir sahne üretilemedi. Lütfen tekrar deneyin.');
        }
      }
    } catch (_) {
      // Tek bir polling hatası akışı bozmasın, bir sonraki tick'te tekrar denenir.
    }
  }

  Future<void> _assemble() async {
    setState(() {
      _assembling = true;
      _assemblyFailed = false;
      _error = null;
    });
    try {
      final finalUrl = await widget.videoService.assemble(_project.projectId);
      final controller = VideoPlayerController.networkUrl(Uri.parse(finalUrl));
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _resultController = controller;
        _assembling = false;
      });
    } on MusicVideoException catch (e) {
      setState(() {
        _error = e.message;
        _assembling = false;
        _assemblyFailed = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Klip birleştirilirken bir hata oluştu.';
        _assembling = false;
        _assemblyFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Klibim')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_resultController != null) return _buildResult();
    if (_assemblyFailed) return _buildAssemblyFailed();
    if (_pollTimer != null || _assembling) return _buildProgress();
    return _buildStoryboardConfirm();
  }

  Widget _buildAssemblyFailed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.error_outline, color: AppColors.pink, size: 36),
        const SizedBox(height: 14),
        const Text(
          'Klip birleştirilemedi',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? 'Beklenmeyen bir hata oluştu.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Birleştirmeyi Tekrar Dene',
          icon: Icons.refresh_rounded,
          onPressed: _assemble,
        ),
      ],
    );
  }

  Widget _buildStoryboardConfirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Klip Planın',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${_project.scenes.length} sahne',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ..._project.scenes.map((scene) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: AppColors.glassCard(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${scene.order + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scene.sceneType,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            scene.prompt,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${scene.duration}s',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppColors.glassCard(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tahmini Maliyet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Text(
                '≈ \$${_project.estimatedCostUsd.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.pink, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        GradientButton(
          label: _starting ? 'Başlatılıyor...' : 'Klibi Oluştur',
          icon: Icons.auto_awesome_rounded,
          isLoading: _starting,
          onPressed: _starting ? null : _startGeneration,
        ),
      ],
    );
  }

  Widget _buildProgress() {
    final total = _project.scenes.length;
    final done = _project.completedSceneCount + _project.failedSceneCount;

    return Column(
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(color: AppColors.pink),
        const SizedBox(height: 20),
        Text(
          _assembling
              ? 'Klip birleştiriliyor...'
              : 'Sahne $done / $total oluşturuluyor...',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        ..._project.scenes.map((scene) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    scene.status == 'completed'
                        ? Icons.check_circle_rounded
                        : scene.status == 'failed'
                            ? Icons.error_rounded
                            : Icons.hourglass_top_rounded,
                    size: 16,
                    color: scene.status == 'completed'
                        ? Colors.greenAccent
                        : scene.status == 'failed'
                            ? AppColors.pink
                            : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sahne ${scene.order + 1} — ${scene.sceneType}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
            )),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppColors.pink, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildResult() {
    final controller = _resultController!;
    return Column(
      children: [
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: VideoPlayer(controller),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  controller.value.isPlaying ? controller.pause() : controller.play();
                });
              },
              icon: Icon(
                controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white,
                size: 48,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GradientButton(
          label: 'Paylaş',
          icon: Icons.share_rounded,
          onPressed: () => SharePlus.instance.share(
            ShareParams(text: 'Melodia ile AI müzik klibimi oluşturdum! 🎬🎵'),
          ),
        ),
      ],
    );
  }
}