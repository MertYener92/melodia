import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/music_spec_service.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'ai_music_screen.dart';

/// "AI Müzik" sekmesinin ilk açılış ekranı: assets/videos/create_hero.mp4'ü
/// tam ekran arka plan olarak oynatan premium bir video-hero ekranı.
/// "Generate Song" CTA'sına basınca, kullanıcının Gelişmiş / Standart /
/// Hızlı modlardan birini seçtiği [AiMusicScreen]'e yönlendirir.
///
/// Bu ekran artık HomeShell'in tab kökü (bağımsız bir alt sayfa değil,
/// "AI Müzik" sekmesinin kendisi) olduğu için kapatma (X) butonu yok —
/// dönülecek "önceki" bir tab yok, bu zaten ana giriş noktası.
class CreateScreen extends StatefulWidget {
  const CreateScreen({
    super.key,
    required this.service,
    required this.musicSpecService,
    required this.library,
    required this.isActive,
  });

  final SunoApiService service;
  final MusicSpecService musicSpecService;
  final SongLibrary library;
  final bool isActive;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  static const _videoAsset = 'assets/videos/create_hero.mp4';

  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(_videoAsset);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (!mounted) return;
      setState(() => _videoReady = true);
      if (widget.isActive) {
        controller.play();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _videoFailed = true);
    }
  }

  @override
  void didUpdateWidget(covariant CreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive || !_videoReady) return;

    final controller = _controller;
    if (controller == null) return;

    if (widget.isActive) {
      // Create sekmesine her tekrar girildiğinde video baştan başlasın.
      controller
        ..seekTo(Duration.zero)
        ..play();
    } else {
      controller.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openModeSelector() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiMusicScreen(
          service: widget.service,
          musicSpecService: widget.musicSpecService,
          library: widget.library,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Tam ekran video arka plan.
        _buildVideoBackground(),

        // 3. Alt tarafta okunabilirlik için koyulaşan gradient.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.72, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0x662A0A38),
                  Color(0xE00A0A12),
                ],
              ),
            ),
          ),
        ),

        // 2. Alt içerik: rozet, başlık, açıklama, CTA.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBadge(),
                const SizedBox(height: 14),
                const Text(
                  'Generate Your Song',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fikirlerinizi saniyeler içinde yapay zeka ile özgün '
                  'şarkılara dönüştürün.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: 'Generate Song',
                  icon: Icons.auto_awesome,
                  onPressed: _openModeSelector,
                  height: 52,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoBackground() {
    final controller = _controller;

    if (_videoFailed || controller == null) {
      // 10. Video yüklenemezse çökmeyen, temiz bir fallback.
      return const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.backgroundGlow),
      );
    }

    if (!_videoReady) {
      // 10. Video hazırlanırken kısa süreli temiz placeholder.
      return const DecoratedBox(
        decoration: BoxDecoration(color: AppColors.background),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: IgnorePointer(
          // Videoya dokununca herhangi bir play/pause kontrolü açılmasın.
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'AI SONG GENERATOR',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}