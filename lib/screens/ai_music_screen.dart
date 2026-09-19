import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/music_spec_service.dart';
import '../services/player_controller.dart';
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
    required this.player,
    required this.authService,
    required this.onOpenSettings,
  });

  final SunoApiService service;
  final MusicSpecService musicSpecService;
  final SongLibrary library;
  final PlayerController player;
  final AuthService authService;

  /// Pro kullanıcıdaki Ayarlar ikonu (bkz. AccountHeaderActions).
  final VoidCallback onOpenSettings;

  @override
  State<AiMusicScreen> createState() => _AiMusicScreenState();
}

class _AiMusicScreenState extends State<AiMusicScreen> {
  @override
  void initState() {
    super.initState();
    // DÜZELTME (kredi rozeti bayatlığı): bkz. create_screen.dart'taki
    // aynı düzeltme. Kota artık widget.library (SongLibrary) singleton'ında
    // merkezi olarak tutuluyor ve her üretim bitişinde orada tazeleniyor;
    // bu ekran sadece dinliyor. Üretim akışı (QuickCreateScreen /
    // CreateFormScreen / MusicWizardScreen) zaten pushAndRemoveUntil ile
    // bu ekranı route yığınından kaldırdığı için eskiden buradaki
    // .then(_loadQuota) hiç tetiklenmiyordu.
    if (widget.library.remainingCredits == null) {
      widget.library.refreshQuota();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                        AppIcons.back,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.navAiMusic,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    l10n.aiMusicSubtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                _ModeCard(
                  title: l10n.modeAdvancedTitle,
                  subtitle: l10n.modeAdvancedSubtitle,
                  icon: Icons.auto_awesome_rounded,
                  gradient: AppColors.primaryGradient,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MusicWizardScreen(
                        service: service,
                        musicSpecService: musicSpecService,
                        library: library,
                        player: widget.player,
                      ),
                    ),
                  ).then((_) => widget.library.refreshQuota()),
                ),
                const SizedBox(height: 14),
                _ModeCard(
                  title: l10n.modeStandardTitle,
                  subtitle: l10n.modeStandardSubtitle,
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
                        player: widget.player,
                      ),
                    ),
                  ).then((_) => widget.library.refreshQuota()),
                ),
                const SizedBox(height: 14),
                _ModeCard(
                  title: l10n.modeQuickTitle,
                  subtitle: l10n.modeQuickSubtitle,
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
                        player: widget.player,
                      ),
                    ),
                  ).then((_) => widget.library.refreshQuota()),
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
                child: AccountHeaderActions(
                  library: widget.library,
                  authService: widget.authService,
                  service: widget.service,
                  onOpenSettings: widget.onOpenSettings,
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
        constraints: const BoxConstraints(minHeight: 118),
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