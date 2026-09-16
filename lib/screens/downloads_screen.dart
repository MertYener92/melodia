import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_back_button.dart';

/// "İndirdiklerim" ekranı — ŞİMDİLİK PLACEHOLDER.
/// Kullanıcının cihazına indirdiği dosyaların gerçek takibi henüz
/// yapılmadı (player_screen.dart'taki indirme işlemi şu an geçici bir
/// klasöre yazıp doğrudan paylaşım menüsünü açıyor, kalıcı bir liste
/// tutmuyor). Bu ekran ileride gerçek indirme geçmişiyle doldurulacak.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // DEĞİŞTİ: Standart Scaffold AppBar KALDIRILDI -- Şarkılarım/
    // Videolarım/Favorilerim ekranlarıyla BİREBİR aynı desen: özel bir
    // başlık satırı (PremiumBackButton + metin), gradyan en tepeden
    // başlıyor, üstte artık siyah bir şerit kalmıyor.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.libraryGranite),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 18),
                child: Row(
                  children: [
                    const PremiumBackButton(),
                    const SizedBox(width: 12),
                    Text(
                      l10n.libraryDownloadsTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.download_rounded, color: AppColors.textMuted, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          l10n.comingSoonTitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.downloadsComingSoonBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}