import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

/// Sinematik, sessiz, otomatik oynatılan, döngülü bir video hero bölümü.
/// Kontrol çubuğu, zaman çizelgesi veya herhangi bir player arayüzü
/// GÖSTERMEZ — sadece dekoratif bir arka plan/banner olarak kullanılır.
///
/// Bilinçli olarak abonelik/paywall UI'ından tamamen BAĞIMSIZ tutuldu
/// (bkz. proje durum notları) — video dosyası ileride değiştiğinde bu
/// widget'a hiç dokunmadan sadece [assetPath] güncellenir.
///
/// Video, kendi gerçek en-boy oranını (16:9) KORUYARAK [height] kadar
/// yükseklikte bir alanı `BoxFit.cover` ile dolduracak şekilde çizilir —
/// gerekirse hafifçe kırpılır ama asla esnetilip bozulmaz.
class CinematicVideoHero extends StatefulWidget {
  const CinematicVideoHero({
    super.key,
    required this.assetPath,
    required this.height,
  });

  final String assetPath;
  final double height;

  @override
  State<CinematicVideoHero> createState() => _CinematicVideoHeroState();
}

class _CinematicVideoHeroState extends State<CinematicVideoHero> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

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
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    // Ekran kapandığında (X'e basılınca) video kaynakları serbest bırakılır.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ClipRect(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: (_failed || controller == null || !_ready)
            ? const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.backgroundGlow),
              )
            : FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  // Video üzerinde dokunma ile play/pause açılmasın —
                  // tamamen dekoratif, kontrolsüz kalmalı.
                  child: IgnorePointer(child: VideoPlayer(controller)),
                ),
              ),
      ),
    );
  }
}