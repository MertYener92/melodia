import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

/// Login ekranı gibi kullanıcının BİR SÜRE bakılı kalabileceği bir arka
/// planda kullanılan, tam ekranı kaplayan, sessiz, SÜREKLİ döngüde oynayan
/// video widget'ı. [CinematicVideoHero] (Pro ekranı) ile kasıtlı olarak
/// AYRI tutuldu -- o bir kez oynayıp duruyor, bu ise ekran açık kaldığı
/// sürece döngüde kalmalı.
class LoopingVideoBackground extends StatefulWidget {
  const LoopingVideoBackground({super.key, required this.assetPath});

  final String assetPath;

  @override
  State<LoopingVideoBackground> createState() => _LoopingVideoBackgroundState();
}

class _LoopingVideoBackgroundState extends State<LoopingVideoBackground> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.asset(widget.assetPath);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (!mounted) return;
      setState(() => _ready = true);
      controller.play();
    } catch (_) {
      if (!mounted) return;
      setState(() {}); // _ready false kalır, yedek gradyan gösterilir.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final hasValidSize = controller != null &&
        controller.value.size.width > 0 &&
        controller.value.size.height > 0;

    if (!_ready || !hasValidSize) {
      // Video hazır olmadan (ya da hiç yüklenemezse) sade bir gradyan --
      // boş/siyah bir çökme YOK.
      return const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.backgroundGlow),
      );
    }

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: IgnorePointer(child: VideoPlayer(controller)),
        ),
      ),
    );
  }
}