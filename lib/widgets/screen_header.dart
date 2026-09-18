import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'premium_back_button.dart';

/// Alt sayfaların (Ayarlar, Hesap Bilgileri, Şarkılarım, Favorilerim ...)
/// ortak üst satırı: solda sade "<" oku, ORTADA küçük ve kalın başlık --
/// klasik iOS gezinme çubuğu düzeni.
///
/// Başlık, Stack içinde ortalandığı için soldaki okun ve (varsa) sağdaki
/// aksiyonun genişliğinden BAĞIMSIZ olarak ekranın tam ortasında durur;
/// Row + Spacer ile yapılsaydı ok tarafına kayardı.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;

  /// Sağ uçtaki isteğe bağlı aksiyon (ör. bir menü ikonu).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Başlık en altta: ok/aksiyon dokunma alanları üstünde kalsın.
          Padding(
            // Uzun başlıklar okun/aksiyonun altına girmesin.
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: PremiumBackButton(onPressed: onBack),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing!),
        ],
      ),
    );
  }
}
