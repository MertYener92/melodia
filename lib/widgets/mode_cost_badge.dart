import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// YENİ (JETON SİSTEMİ x10 GÜNCELLEMESİ): kullanıcı üretime başlamadan
/// ÖNCE, bu üretimin kaç jetona mal olacağını ve kaç şarkı döneceğini
/// (Suno her istekte 2 farklı şarkı döndürüyor) net olarak görsün diye.
/// Üç mod ekranında (quick_create_screen/create_form_screen/
/// music_wizard_screen) submit butonunun hemen üzerinde kullanılır.
class ModeCostBadge extends StatelessWidget {
  const ModeCostBadge({super.key, required this.credits, required this.songCount});

  final int credits;
  final int songCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.diamond_rounded, color: Color(0xFFF4B740), size: 13),
        const SizedBox(width: 5),
        Text(
          '$credits Kredi',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
        Text(
          '$songCount Şarkı',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
