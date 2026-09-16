import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/locale_controller.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_back_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.service,
    required this.authService,
    required this.localeController,
    required this.onAccountDeleted,
  });

  final SunoApiService service;
  final AuthService authService;
  final LocaleController localeController;

  /// Hesap başarıyla silindikten sonra çağrılır — uygulamanın üst
  /// seviyesinde (main.dart) oturumu kapatıp login ekranına dönmek için.
  final VoidCallback onAccountDeleted;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _deleting = false;

  static const Map<String, String> _languageNames = {
    'en': 'English',
    'tr': 'Türkçe',
    'es': 'Español',
  };

  Future<void> _openLanguagePicker() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    l10n.settingsLanguagePickerTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Sistem dilini takip et (kayıtlı bir tercih varsa siler).
                ListTile(
                  leading: Icon(
                    Icons.smartphone_rounded,
                    color: widget.localeController.locale == null
                        ? AppColors.pink
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    l10n.settingsLanguageSystemDefault,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  trailing: widget.localeController.locale == null
                      ? const Icon(Icons.check_rounded, color: AppColors.pink)
                      : null,
                  onTap: () async {
                    await widget.localeController.useSystemDefault();
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                ),
                for (final locale in LocaleController.supportedLocalesList)
                  ListTile(
                    leading: Icon(
                      Icons.language_rounded,
                      color: widget.localeController.locale?.languageCode ==
                              locale.languageCode
                          ? AppColors.pink
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      _languageNames[locale.languageCode] ?? locale.languageCode,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    trailing: widget.localeController.locale?.languageCode ==
                            locale.languageCode
                        ? const Icon(Icons.check_rounded, color: AppColors.pink)
                        : null,
                    onTap: () async {
                      await widget.localeController.setLocale(locale);
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(
          l10n.deleteAccountConfirmTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.deleteAccountConfirmBody,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.deleteAccountShort,
              style: const TextStyle(color: AppColors.pink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await widget.service.deleteAccount();
      await widget.authService.signOut();
      if (!mounted) return;
      // DÜZELTME: Çıkış Yap'taki ile aynı sebep -- bu ekran pushed bir
      // route, önce onu kapatıp en alt route'a dönmemiz gerekiyor.
      Navigator.of(context).popUntil((route) => route.isFirst);
      widget.onAccountDeleted();
    } on SunoApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.genericUnexpectedError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // DÜZELTME ("ayarların olduğu kısım siyah kalmış" geri bildirimi):
    // standart AppBar'ın kendi (temadan gelen, düz koyu) arka planı ile
    // hemen altındaki backgroundGlow gradyanının üst rengi arasında
    // görünür bir sınır/renk sıçraması oluşuyordu. my_songs_screen.dart
    // ile BİREBİR aynı çözüm: standart AppBar KALDIRILDI, ekran kendi
    // gradyanını ve geri butonunu yönetiyor, gradyan en tepeden
    // (durum çubuğunun hemen altından) başlıyor.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  children: [
                    const PremiumBackButton(),
                    const SizedBox(width: 12),
                    Text(
                      l10n.profileSettings,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: AppColors.glassCard(radius: 14),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language_rounded, color: AppColors.textSecondary),
                      title: Text(l10n.settingsLanguage, style: const TextStyle(color: AppColors.textPrimary)),
                      trailing: Text(
                        _languageNames[widget.localeController.effectiveLanguageCode] ?? '',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      onTap: _openLanguagePicker,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                      title: Text(l10n.actionLogout, style: const TextStyle(color: AppColors.textPrimary)),
                      onTap: () async {
                        await widget.authService.signOut();
                        if (!context.mounted) return;
                        // DÜZELTME: Bu ekran (Ayarlar) Navigator'da üste
                        // itilmiş (pushed) bir route. Oturum durumu
                        // değişip _AppRoot LoginScreen'e geçse bile, bu
                        // route Navigator yığınının EN ÜSTÜNDE kaldığı
                        // sürece görünüm değişmiyordu -- kullanıcı "geri"
                        // basıp bu route'u kapatana kadar hiçbir şey olmuş
                        // gibi görünmüyordu. Önce bu route'u (ve varsa
                        // üzerine gelmiş başka route'ları) kapatıp en alt
                        // route'a dönüyoruz, SONRA oturumu kapatıyoruz --
                        // böylece LoginScreen hemen görünür.
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        widget.onAccountDeleted();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.dangerZoneTitle,
                style: const TextStyle(
                  color: AppColors.pink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.pink.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deleteAccountShort,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.deleteAccountBody,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _deleting ? null : _confirmDeleteAccount,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.pink),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: _deleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pink),
                              )
                            : Text(
                                l10n.deleteAccountPermanentButton,
                                style: const TextStyle(color: AppColors.pink, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}