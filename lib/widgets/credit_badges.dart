import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kalan jetonu (şarkı ya da video — bağlama göre farklı bir servisten
/// gelir) gösteren küçük rozet. CreateScreen, AiMusicScreen ve
/// AiVideoScreen'de aynı görünümü kullanmak için buraya taşındı — ikon/renk
/// değiştirmek istendiğinde tek bir yer güncellenir.
///
/// [remaining] null iken (ilk açılış anındaki kısa an ya da istek
/// başarısız olduğunda) ve [error] de null ise sessizce boş bir SizedBox
/// döner. [error] doluysa (GEÇİCİ debug amaçlı) küçük kırmızı bir uyarı
/// rozeti gösterir — dokununca tam hata mesajını diyalogda açar, böylece
/// konsola bakmadan ekran görüntüsüyle paylaşılabilir.
class CreditsBadge extends StatelessWidget {
  const CreditsBadge({super.key, required this.remaining, this.error});

  final int? remaining;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (remaining != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFF4B740), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond_rounded, color: Color(0xFFF4B740), size: 13),
            const SizedBox(width: 5),
            Text(
              '$remaining',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // GEÇİCİ: jeton isteği başarısız olduysa sessizce gizlenmek yerine
    // dokunulabilir bir uyarı göster — gerçek neden netleşince bu blok
    // kaldırılabilir.
    if (error != null) {
      return GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Jeton bilgisi alınamadı'),
            content: SelectableText(error!),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.redAccent, width: 1),
          ),
          child: const Icon(Icons.priority_high_rounded, color: Colors.redAccent, size: 14),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Sağ üst köşede jeton rozetinin yanında görünen sabit "Pro" rozeti.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}