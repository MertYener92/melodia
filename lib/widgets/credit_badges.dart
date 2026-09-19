import 'package:flutter/material.dart';

import '../screens/credits_screen.dart';
import '../screens/pro_upsell_screen.dart';
import '../services/auth_service.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
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

/// Pro OLMAYAN kullanıcıya gösterilen "Pro" butonu (Pro'ya geçiş ekranını
/// açar). DEĞİŞTİ: Pro kullanıcıya gösterilen "Kredi Al" varyantı kaldırıldı
/// -- Pro kullanıcı artık kredi rozetine dokunarak ek kredi alıyor (bkz.
/// AccountHeaderActions).
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
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
              fontFamily: AppFonts.rounded,
              fontFamilyFallback: AppFonts.roundedFallback,
              color: Colors.white,
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

/// Ekranların sağ üst köşesindeki hesap aksiyonları (AI Müzik, Kütüphane):
///  - Pro OLMAYAN kullanıcı: sadece "Pro" butonu (Pro ekranını açar).
///  - Pro kullanıcı: kalan kredi rozeti (dokununca ek kredi paketleri) ve
///    yanında profildeki ile aynı Ayarlar ikonu.
/// Satın alma ekranı kapanınca kredi bilgisi tazelenir.
class AccountHeaderActions extends StatelessWidget {
  const AccountHeaderActions({
    super.key,
    required this.library,
    required this.authService,
    required this.service,
    required this.onOpenSettings,
  });

  final SongLibrary library;
  final AuthService authService;
  final SunoApiService service;
  final VoidCallback onOpenSettings;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => screen))
        .then((_) => library.refreshQuota());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) {
        if (!library.isPro) {
          return ProBadge(
            onTap: () => _open(
              context,
              ProUpsellScreen(authService: authService, apiService: service),
            ),
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _open(
                context,
                CreditsScreen(authService: authService, apiService: service),
              ),
              child: CreditsBadge(
                remaining: library.remainingCredits,
                bonusCredits: library.bonusCredits,
                error: library.quotaError,
              ),
            ),
            const SizedBox(width: 8),
            SettingsIconButton(onTap: onOpenSettings),
          ],
        );
      },
    );
  }
}

/// Profil ekranındaki ile aynı görünümde yuvarlak Ayarlar butonu.
class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({super.key, required this.onTap, this.size = 34});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ayarlar',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.settings_outlined, color: Colors.white, size: size * 0.54),
        ),
      ),
    );
  }
}
