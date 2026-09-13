import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.libraryDownloadsTitle)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
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
      ),
    );
  }
}