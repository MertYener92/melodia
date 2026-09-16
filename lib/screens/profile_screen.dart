import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/locale_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_border_painter.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.library,
    required this.service,
    required this.authService,
    required this.localeController,
    required this.onLoggedOut,
  });

  final SongLibrary library;
  final SunoApiService service;
  final AuthService authService;
  final LocaleController localeController;

  /// Çıkış yapıldığında ya da hesap silindiğinde çağrılır (main.dart'a
  /// kadar bubbling yaparak login ekranına dönmeyi sağlar).
  final VoidCallback onLoggedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // YENİ: Kullanılan abonelik planı -- avatarın hemen altında rozet
  // olarak gösteriliyor. getQuota() zaten backend'den bu bilgiyi
  // döndürüyor (home_shell.dart'taki Pro-upsell kontrolüyle AYNI
  // kaynak), ayrı bir uç nokta eklemeye gerek kalmadı.
  String? _planLabel;
  bool _isPro = false;
  bool _planLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final quota = await widget.service.getQuota();
      if (!mounted) return;
      setState(() {
        _isPro = quota.plan.startsWith('pro_');
        _planLabel = _planLabelFor(quota.plan);
        _planLoaded = true;
      });
    } catch (_) {
      // Sessizce yut -- plan rozeti gösterilmeden devam eder, ekranın
      // geri kalanı (istatistikler, menü) yine normal çalışır.
      if (mounted) setState(() => _planLoaded = true);
    }
  }

  String _planLabelFor(String plan) {
    switch (plan) {
      case 'pro_weekly':
        return 'Pro · Haftalık';
      case 'pro_monthly':
        return 'Pro · Aylık';
      case 'pro_yearly':
        return 'Pro · Yıllık';
      default:
        return 'Ücretsiz Plan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: ListenableBuilder(
        listenable: widget.library,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              // DEĞİŞTİ (premium yeniden tasarım): avatarın etrafına
              // kütüphane ekranlarındaki filtre çipleri/geri butonuyla
              // AYNI altınımsı, renk geçişli gradyan halka eklendi --
              // "çok sade/basit duruyor" geri bildirimi üzerine.
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(100, 100),
                        painter: const GradientBorderPainter(
                          gradient: AppColors.goldGradient,
                          borderRadius: 50,
                          strokeWidth: 2.2,
                        ),
                      ),
                      Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // YENİ: Kullanılan plan rozeti -- ana avatarın hemen
              // altında. Pro planlar altınımsı gradyan dolgu, ücretsiz
              // plan daha sade/nötr bir rozet taşıyor.
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _planLoaded ? 1 : 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: _isPro ? AppColors.goldGradient : null,
                      color: _isPro ? null : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(999),
                      border: _isPro ? null : Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isPro) ...[
                          const Icon(Icons.workspace_premium_rounded, size: 13, color: Colors.black87),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          _planLabel ?? '',
                          style: TextStyle(
                            color: _isPro ? Colors.black.withValues(alpha: 0.85) : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  l10n.profileTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _StatCard(
                    label: l10n.profileSongs,
                    value: '${widget.library.songs.length}',
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: l10n.profileFavorites,
                    value:
                        '${widget.library.songs.where((s) => s.isFavorite).length}',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _MenuTile(
                icon: Icons.settings_outlined,
                label: l10n.profileSettings,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      service: widget.service,
                      authService: widget.authService,
                      localeController: widget.localeController,
                      onAccountDeleted: widget.onLoggedOut,
                    ),
                  ),
                ),
              ),
              _MenuTile(
                icon: Icons.workspace_premium_outlined,
                label: l10n.profileUpgradePlan,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PaywallScreen(
                        authService: widget.authService,
                        apiService: widget.service,
                      ),
                    ),
                  );
                  // Paywall'dan dönünce plan değişmiş olabilir (satın
                  // alma başarılı oldu) -- rozeti taze bilgiyle güncelle.
                  _loadPlan();
                },
              ),
              _MenuTile(icon: Icons.help_outline, label: l10n.profileHelpSupport),
              _MenuTile(icon: Icons.info_outline, label: l10n.profileAboutApp),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: AppColors.glassCard(radius: 16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppColors.glassCard(radius: 14),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textMuted,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }
}