import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'gradient_border_painter.dart';

/// Kütüphane ekranlarının (Şarkılarım/Videolarım/Favorilerim/
/// İndirdiklerim) üst kısmındaki geri butonu -- önceden çıplak, sade
/// bir ok ikonuydu ("çok sade/basit duruyor" geri bildirimi üzerine),
/// artık altınımsı, renk geçişli bir halka içinde, dairesel "premium"
/// bir görünüm taşıyor.
class PremiumBackButton extends StatelessWidget {
  const PremiumBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: _size,
          height: _size,
          child: CustomPaint(
            painter: const GradientBorderPainter(
              gradient: AppColors.goldGradient,
              borderRadius: _size / 2,
              strokeWidth: 1.4,
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
