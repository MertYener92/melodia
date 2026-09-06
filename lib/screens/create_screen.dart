import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'create_form_screen.dart';

/// "Create" sekmesi: assets/videos/create_hero.mp4'ü tam ekran arka plan
/// olarak oynatan premium bir video-hero ekranı. Gerçek şarkı üretim formu
/// (prompt + genre/mood/vocal/length + Suno API çağrısı) [CreateFormScreen]
/// içine taşındı; buradaki "Generate Song" CTA'sı o forma yönlendirir.
///
/// Bu ekran, HomeShell'deki IndexedStack tab yapısını bozmadan bir tab
/// olarak kalır (mevcut bottom navigation mimarisi korunur). [isActive],
/// tab aktif değilken videoyu duraklatmak / tekrar aktif olunca baştan
/// başlatmak için HomeShell tarafından sağlanır. [onClose], sol üstteki X
/// butonuna basıldığında Home sekmesine dönmek için kullanılır.
class CreateScreen extends StatefulWidget {
  const CreateScreen({
    super.key,
    required this.service,
    required this.library,
    required this.isActive,
    required this.onClose,
  });

  final SunoApiService service;
  final SongLibrary library;
  final bool isActive;
  final VoidCallback onClose;

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

  void _openGenerateForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateFormScreen(
          service: widget.service,
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
                stops: [0.0, 0.55, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0x992A0A38),
                  Color(0xF00A0A12),
                ],
              ),
            ),
          ),
        ),

        // 2. Üst sol kapatma butonu.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: _CloseButton(onTap: widget.onClose),
            ),
          ),
        ),

        // 4-7. Alt içerik: rozet, başlık, açıklama, CTA.
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
                  onPressed: _openGenerateForm,
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

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}