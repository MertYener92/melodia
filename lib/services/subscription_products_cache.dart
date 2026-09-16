import 'package:in_app_purchase/in_app_purchase.dart';
import 'subscription_service.dart';

/// PRO ekranı ("ProUpsellScreen") her açıldığında Apple'dan ürün
/// bilgilerini YENİDEN çekiyordu -- bu 1-2 saniye sürdüğü için, ekran
/// açılır açılmaz önce kısa bir yükleme göstergesi, sonra ANİDEN tam
/// fiyat kartları görünüyordu (görünür bir "kayma").
///
/// BİLİNÇLİ TASARIM KARARI: [ProScreenSessionGate] ile AYNI desen --
/// SADECE bellekte (RAM) tutulan statik bir önbellek, diske hiç
/// yazılmıyor. HomeShell açılır açılmaz (PRO ekranı otomatik olarak en
/// erken 9sn sonra açılabiliyor, bkz. home_shell.dart) arka planda bir
/// kez doldurulur -- ProUpsellScreen açıldığında bu önbellek doluysa
/// yükleme durumu HİÇ GÖSTERİLMEZ, fiyatlar ekran ilk çizildiği anda
/// zaten hazırdır.
class SubscriptionProductsCache {
  SubscriptionProductsCache._();

  static List<ProductDetails>? products;
  static Future<List<ProductDetails>>? _inFlight;

  /// Arka planda bir kez tetiklenir (HomeShell.initState). Zaten devam
  /// eden bir istek varsa (ör. hızlı art arda çağrılırsa) onu paylaşır,
  /// ikinci bir ağ isteği ATMAZ.
  static Future<void> prefetch(SubscriptionService service) async {
    if (products != null || _inFlight != null) return;
    final future = service.loadProducts();
    _inFlight = future;
    try {
      products = await future;
    } catch (_) {
      // Sessizce yut -- ProUpsellScreen kendi açıldığında normal
      // şekilde (yeniden) deneyecek, kullanıcıya burada bir hata
      // göstermeye gerek yok (ekran henüz açık bile değil).
    } finally {
      _inFlight = null;
    }
  }
}
