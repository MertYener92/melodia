import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Uygulama açılışında gösterilen video splash ekranı.
///
/// DAVRANIŞ (kullanıcı isteğiyle birebir):
/// - Tamamen SİYAH arka plan.
/// - assets/videos/melodia-splash.mp4 TAM OLARAK BİR KEZ oynatılır (loop YOK).
/// - Hiçbir loading spinner/progress indicator GÖSTERİLMEZ — video'nun
///   kendisi zaten bir "yükleniyor" hissi veriyor.
/// - Video bittiğinde (video_player'ın doğal davranışı gereği) son karede
///   duraklamış halde kalır; biz üstüne 1 saniye daha bekleyip [onFinished]
///   çağırıyoruz (toplam ~video süresi + 1sn ≈ 4 saniye).
/// - [onFinished] çağrıldığında video kaynakları serbest bırakılır.
class SplashVideoScreen extends StatefulWidget {
  const SplashVideoScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashVideoScreen> createState() => _SplashVideoScreenState();
}

class _SplashVideoScreenState extends State<SplashVideoScreen> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.asset(
      'assets/videos/melodia-splash.mp4',
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false); // KESİNLİKLE tekrar oynatılmasın
      if (!mounted) return;
      setState(() => _ready = true);
      await controller.play();

      // Video ~3sn sürüyor; bittikten sonra son karede 1sn daha bekleyip
      // ana ekrana geçiyoruz (toplam splash süresi ≈ video süresi + 1sn).
      // video_player, loop kapalıyken oynatma bitince otomatik durur ve
      // son kareyi göstermeye devam eder -- ekstra bir "freeze" mantığı
      // yazmaya gerek yok, sadece bekleyip geçişi tetikliyoruz.
      final holdDelay = controller.value.duration + const Duration(seconds: 1);
      await Future.delayed(holdDelay);
    } catch (_) {
      // Video hiç yüklenemezse (dosya eksik/bozuk) splash'te sonsuza kadar
      // takılı kalınmasın -- kısa bir bekleme sonrası yine de devam et.
      await Future.delayed(const Duration(seconds: 2));
    }
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: (_ready && controller != null)
            ? FractionallySizedBox(
                // "Ekranın ortasında" -- tam ekran değil, orantılı ve
                // ölçülü bir alanda, video kendi en-boy oranını koruyarak.
                widthFactor: 0.62,
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              )
            // Video henüz initialize olurken (çok kısa bir an) de SADECE
            // siyah ekran -- spinner/başka hiçbir şey YOK.
            : const SizedBox.shrink(),
      ),
    );
  }
}