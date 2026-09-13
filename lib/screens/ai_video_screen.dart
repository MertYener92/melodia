import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/music_video_service.dart';
import '../theme/app_theme.dart';
import '../widgets/credit_badges.dart';

/// GEÇİCİ: "My Songs" sekmesinin yerini alan yeni "AI Video" sekmesi.
/// İçerik henüz tasarlanmadı — asıl klip oluşturma akışı ayrı ekranlarda
/// (select_video_package_screen.dart vb.) yaşıyor. Bu sekme şimdilik sadece
/// başlık + kalan video jetonu rozetini gösteriyor; navigasyonun (bottom
/// nav + tab sırası) doğru çalıştığını göstermek için yer tutucu.
class AiVideoScreen extends StatefulWidget {
  const AiVideoScreen({super.key, required this.service});

  final MusicVideoService service;

  @override
  State<AiVideoScreen> createState() => _AiVideoScreenState();
}

class _AiVideoScreenState extends State<AiVideoScreen> {
  int? _remainingCredits;
  String? _creditsError;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await widget.service.getCreditsBalance();
      if (!mounted) return;
      setState(() {
        _remainingCredits = balance;
        _creditsError = null;
      });
    } catch (e) {
      debugPrint('[AiVideoScreen] getCreditsBalance() başarısız: $e');
      if (!mounted) return;
      setState(() => _creditsError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Video',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bu bölüm yakında burada olacak.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Yapım aşamasında',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sağ üst köşede jeton + Pro rozeti. CreateScreen ve AiMusicScreen
        // ile BİREBİR aynı padding (20,16,20,0) ve Align(topRight) — başlık
        // satırından bağımsız ayrı bir overlay katmanı, üç sekmede de aynı
        // piksel konumda durması için.
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CreditsBadge(remaining: _remainingCredits, error: _creditsError),
                  const SizedBox(width: 8),
                  const ProBadge(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}