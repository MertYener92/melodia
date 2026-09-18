import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Uygulamanın tüm geri butonu: sade, ince bir "<" ok. Yanındaki başlık
/// (varsa) çağıran ekranın satırında durur. Sınırsız/dairesiz -- tek
/// tanım burada, AppBar'lı ekranlar da aynı ikonu temadan alır
/// (bkz. AppTheme.dark -> actionIconTheme).
class PremiumBackButton extends StatelessWidget {
  const PremiumBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      radius: 22,
      child: const SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          AppIcons.back,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}
