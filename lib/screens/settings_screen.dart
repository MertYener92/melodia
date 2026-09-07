import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.service,
    required this.authService,
    required this.onAccountDeleted,
  });

  final SunoApiService service;
  final AuthService authService;

  /// Hesap başarıyla silindikten sonra çağrılır — uygulamanın üst
  /// seviyesinde (main.dart) oturumu kapatıp login ekranına dönmek için.
  final VoidCallback onAccountDeleted;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _deleting = false;

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text(
          'Hesabını kalıcı olarak sil',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Bu işlem geri alınamaz. Tüm şarkıların, video kliplerin ve '
          'hesap bilgilerin KALICI olarak silinecek. Devam etmek '
          'istediğine emin misin?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Hesabımı Sil',
              style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.w700),
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
      widget.onAccountDeleted();
    } on SunoApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beklenmeyen bir hata oluştu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Container(
                decoration: AppColors.glassCard(radius: 14),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                      title: const Text('Çıkış Yap', style: TextStyle(color: AppColors.textPrimary)),
                      onTap: () async {
                        await widget.authService.signOut();
                        if (mounted) widget.onAccountDeleted();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'TEHLİKELİ BÖLGE',
                style: TextStyle(
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
                    const Text(
                      'Hesabımı Sil',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tüm şarkıların, video kliplerin ve hesap bilgilerin '
                      'kalıcı olarak silinir. Bu işlem geri alınamaz.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
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
                            : const Text(
                                'Hesabımı Kalıcı Olarak Sil',
                                style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.w600),
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