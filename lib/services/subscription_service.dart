import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'auth_service.dart';
import 'suno_api_service.dart';

/// StoreKit 2 üzerinden Pro abonelik satın alma akışını yönetir.
///
/// ÖNEMLİ (backend ile bağlantı): satın alma isteği atılırken
/// appAccountToken olarak Cognito 'sub' değeri (AuthService.userId)
/// Apple'a gönderiliyor. Bu olmadan backend'deki verifySubscription.js
/// gelen makbuzu doğru kullanıcıyla eşleştiremez ve isteği reddeder.
class SubscriptionService {
  SubscriptionService({required this.authService, required this.apiService});

  final AuthService authService;
  final SunoApiService apiService;

  // App Store Connect'te oluşturulan gerçek product ID'ler.
  static const Set<String> productIds = {
    'com.melodia.app.pro.weekly',
    'com.melodia.app.pro.monthly',
    'com.melodia.app.pro.yearly',
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final _statusController =
      StreamController<SubscriptionPurchaseStatus>.broadcast();

  /// UI, satın alma sonucunu (beklemede/başarılı/hatalı) buradan dinler.
  Stream<SubscriptionPurchaseStatus> get statusStream =>
      _statusController.stream;

  /// Mevcut 3 Pro ürününü Apple'dan çeker. Sırayı weekly -> monthly ->
  /// yearly olacak şekilde sabitliyoruz (Apple'ın döndürdüğü sıra garanti
  /// değil).
  Future<List<ProductDetails>> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) {
      throw Exception('Mağaza şu anda kullanılamıyor.');
    }

    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    if (response.productDetails.isEmpty) {
      throw Exception(
        'Ürünler bulunamadı — App Store Connect\'teki abonelikler henüz '
        'onaylanmamış/yayında olmayabilir, ya da Sandbox test hesabıyla '
        'giriş yapılmamış olabilir.',
      );
    }

    final order = productIds.toList();
    final sorted = [...response.productDetails]..sort(
      (a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)),
    );
    return sorted;
  }

  /// Satın alma sonuçlarını dinlemeye başlar. Paywall ekranı açıldığında
  /// bir kez çağrılmalı, kapanırken [dispose] ile durdurulmalı.
  void startListening() {
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _statusController.add(
          SubscriptionPurchaseStatus.error('Satın alma hatası: $error'),
        );
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }

  Future<void> buy(ProductDetails product) async {
    final userId = authService.userId;
    if (userId == null) {
      throw Exception('Giriş yapılmamış — satın alma başlatılamadı.');
    }

    final PurchaseParam purchaseParam;
    if (Platform.isIOS) {
      // Sk2PurchaseParam -> StoreKit 2 (varsayılan, iOS 15+). Buradaki
      // 'applicationUserName' alanı, plugin tarafından StoreKit 2'nin
      // appAccountToken'ına eşleniyor (bkz. in_app_purchase_storekit
      // kaynak kodu) -- backend bunu userId ile eşleştirip doğruluyor.
      purchaseParam = Sk2PurchaseParam(
        productDetails: product,
        applicationUserName: userId,
      );
    } else {
      purchaseParam = PurchaseParam(productDetails: product);
    }

    // Abonelikler App Store'da "non-consumable" akışıyla satın alınır.
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    // Sonuç senkron dönmüyor — asıl sonuç purchaseStream'den gelecek,
    // bkz. _handlePurchaseUpdates.
  }

  /// "Satın alımları geri yükle" — kullanıcı telefon değiştirdiğinde ya
  /// da uygulamayı silip yeniden kurduğunda gerekli.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _statusController.add(SubscriptionPurchaseStatus.pending());

        case PurchaseStatus.error:
          _statusController.add(
            SubscriptionPurchaseStatus.error(
              purchase.error?.message ?? 'Satın alma başarısız oldu.',
            ),
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

        case PurchaseStatus.canceled:
          _statusController.add(
            SubscriptionPurchaseStatus.error('Satın alma iptal edildi.'),
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            // GÜVENLİK: Apple'ın imzaladığı makbuzu OLDUĞU GİBİ backend'e
            // gönderiyoruz — burada hiçbir doğrulama yapmıyoruz, gerçek
            // doğrulama sunucu tarafında (verifySubscription.js) Apple'ın
            // resmi kütüphanesiyle yapılıyor.
            final signedTransactionInfo =
                purchase.verificationData.serverVerificationData;
            final result = await apiService.verifySubscription(
              signedTransactionInfo,
            );
            _statusController.add(
              SubscriptionPurchaseStatus.success(plan: result.plan),
            );
          } catch (e) {
            _statusController.add(
              SubscriptionPurchaseStatus.error('Doğrulama başarısız: $e'),
            );
          } finally {
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
          }
      }
    }
  }
}

enum SubscriptionStatusType { pending, success, error }

class SubscriptionPurchaseStatus {
  SubscriptionPurchaseStatus._(this.type, {this.message, this.plan});

  factory SubscriptionPurchaseStatus.pending() =>
      SubscriptionPurchaseStatus._(SubscriptionStatusType.pending);

  factory SubscriptionPurchaseStatus.success({String? plan}) =>
      SubscriptionPurchaseStatus._(SubscriptionStatusType.success, plan: plan);

  factory SubscriptionPurchaseStatus.error(String message) =>
      SubscriptionPurchaseStatus._(SubscriptionStatusType.error, message: message);

  final SubscriptionStatusType type;
  final String? message;
  final String? plan;

  bool get isPending => type == SubscriptionStatusType.pending;
  bool get isSuccess => type == SubscriptionStatusType.success;
  bool get isError => type == SubscriptionStatusType.error;
}