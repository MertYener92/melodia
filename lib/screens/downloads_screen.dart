import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('İndirdiklerim')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, color: AppColors.textMuted, size: 40),
                  SizedBox(height: 16),
                  Text(
                    'Bu özellik yakında',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Cihazına indirdiğin şarkı ve videoları burada '
                    'görebileceğin bu özellik üzerinde çalışıyoruz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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