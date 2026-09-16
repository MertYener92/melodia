import 'package:flutter/material.dart';

/// Herhangi bir kutunun etrafına gradyanlı (tek düz renk değil, renk
/// geçişli) bir çerçeve çizen paylaşılan painter. Flutter'ın standart
/// [Border]'ı SADECE düz renk destekler -- premium, altınımsı halka/
/// çerçeve efektleri (kütüphane filtre çipleri, geri butonu vb.) için
/// bu kullanılıyor. İçi TAMAMEN şeffaf bırakılır (fill yok, sadece
/// stroke), böylece hangi arka planın önünde kullanılırsa kullanılsın
/// arkası olduğu gibi görünür.
class GradientBorderPainter extends CustomPainter {
  const GradientBorderPainter({
    required this.gradient,
    required this.borderRadius,
    required this.strokeWidth,
  });

  final Gradient gradient;
  final double borderRadius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GradientBorderPainter oldDelegate) =>
      oldDelegate.gradient != gradient ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.borderRadius != borderRadius;
}
