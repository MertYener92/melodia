import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/music_spec_service.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/credit_badges.dart';
import 'create_form_screen.dart';
import 'music_wizard_screen.dart';
import 'quick_create_screen.dart';

/// "AI Müzik" sekmesi (eski Home sekmesinin yerini alır). Kullanıcıya 3
/// farklı üretim modu sunar; her biri kendi ayrı sayfasına yönlendirir:
///
/// - Hızlı: tek cümlelik fikir + Oluştur (en az soru)
/// - Standart: mevcut prompt + genre/mood/vocal/length formu
/// - Gelişmiş: çok adımlı "sihirbaz" — kullanıcı müziği insan gibi tarif
///   eder, backend (Bedrock) bunu profesyonel bir Music Specification'a
///   çevirir.
class AiMusicScreen extends StatefulWidget {
  const AiMusicScreen({
    super.key,
    required this.service,
    required this.musicSpecService,
    required this.library,
  });

  final SunoApiService service;
  final MusicSpecService musicSpecService;
  final SongLibrary library;

  @override
  State<AiMusicScreen> createState() => _AiMusicScreenState();
}

class _AiMusicScreenState extends State<AiMusicScreen> {
  int? _remainingCredits;
  String? _quotaError;

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    try {
      final quota = await widget.service.getQuota();
      if (!mounted) return;
      setState(() {
        _remainingCredits = quota.remaining;
        _quotaError = null;
      });
    } catch (e) {
      debugPrint('[AiMusicScreen] getQuota() başarısız: $e');
      if (!mounted) return;
      setState(() => _quotaError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final musicSpecService = widget.musicSpecService;
    final library = widget.library;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'AI Müzik',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 32),
                  child: Text(
                    'Aklındaki şarkıyı tarif et, gerisini biz halledelim.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                _ModeCard(
                  title: 'Gelişmiş',
                  subtitle:
                      'Müziği insan gibi tarif et — dünyasını, hissini, hikayesini '
                      'anlat. Yapay zeka profesyonel bir prodüksiyona çevirsin.',
                  icon: Icons.auto_awesome_rounded,
                  gradient: AppColors.primaryGradient,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MusicWizardScreen(
                        service: service,
                        musicSpecService: musicSpecService,
                        library: library,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _ModeCard(
                  title: 'Standart',
                  subtitle:
                      'Tarz, ruh hali, vokal ve süreyi kendin seç — hızlı ve net '
                      'bir form.',
                  icon: Icons.tune_rounded,
                  gradient: const LinearGradient(
                    colors: [AppColors.surfaceElevated, AppColors.surfaceElevated],
                  ),
                  iconColor: AppColors.purple,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateFormScreen(
                        service: service,
                        library: library,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _ModeCard(
                  title: 'Hızlı',
                  subtitle:
                      'Tek cümlede anlat, gerisini yapay zeka tamamlasın. En hızlı '
                      'yol.',
                  icon: Icons.bolt_rounded,
                  gradient: const LinearGradient(
                    colors: [AppColors.surfaceElevated, AppColors.surfaceElevated],
                  ),
                  iconColor: AppColors.pink,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuickCreateScreen(
                        service: service,
                        musicSpecService: musicSpecService,
                        library: library,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
          ),

          // Sağ üst köşede jeton + Pro rozeti. CreateScreen ve AiVideoScreen
          // ile BİREBİR aynı padding (20,16,...) ve Align(topRight) — geri
          // butonu/başlık satırından bağımsız, üç sekmede de aynı piksel
          // konumda durması için ayrı bir overlay katmanı.
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CreditsBadge(remaining: _remainingCredits, error: _quotaError),
                    const SizedBox(width: 8),
                    const ProBadge(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppColors.glassCard(),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
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
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}