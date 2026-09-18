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
  const CreditsBadge({super.key, required this.remaining, this.bonusCredits = 0, this.error});

  final int? remaining;
  // YENİ (kredi paketleri): periyodik havuzdan AYRI, satın alınmış ekstra
  // bakiye -- toplam kullanılabilir jetonu göstermek için remaining'e
  // eklenir.
  final int bonusCredits;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (remaining != null) {
      final total = remaining! + bonusCredits;
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
              '$total',
              style: const TextStyle(
                fontFamily: AppFonts.rounded,
                fontFamilyFallback: AppFonts.roundedFallback,
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
            title: const Text('Kredi bilgisi alınamadı'),
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

/// Sağ üst köşede jeton rozetinin yanında görünen rozet. Pro OLMAYAN
/// kullanıcıya sabit "Pro" rozetini (Pro'ya geçiş ekranını açar), Pro
/// OLAN kullanıcıya ise "Kredi Al" rozetini (kredi paketi satın alma
/// ekranını açar) gösterir -- ikisi hiçbir zaman aynı anda görünmez,
/// çünkü Pro kullanıcıya tekrar "Pro'ya geç" demenin anlamı yok.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.onTap, this.isPro = false});

  final VoidCallback? onTap;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: isPro ? null : AppColors.primaryGradient,
        color: isPro ? AppColors.surfaceElevated : null,
        borderRadius: BorderRadius.circular(999),
        border: isPro ? Border.all(color: const Color(0xFFF4B740), width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.add_circle_rounded : Icons.star_rounded,
            color: isPro ? const Color(0xFFF4B740) : Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isPro ? 'Kredi Al' : 'Pro',
            style: TextStyle(
              fontFamily: AppFonts.rounded,
              fontFamilyFallback: AppFonts.roundedFallback,
              color: isPro ? AppColors.textPrimary : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }
}