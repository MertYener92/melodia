import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// GEÇİCİ: "My Songs" sekmesinin yerini alan yeni "AI Video" sekmesi.
/// İçerik henüz tasarlanmadı — bu, sadece navigasyonun (bottom nav +
/// tab sırası) doğru çalıştığını göstermek için boş bir yer tutucu.
/// İçeriği eklerken bu dosyayı doldurman yeterli, home_shell.dart'a
/// dokunmana gerek kalmaz.
class AiVideoScreen extends StatelessWidget {
  const AiVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
    );
  }
}