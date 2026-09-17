import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'auth_service.dart';
import 'suno_api_service.dart';

/// StoreKit üzerinden tüketilebilir (consumable) kredi paketi satın alma
/// akışını yönetir. subscription_service.dart ile BİREBİR AYNI desen —
/// tek fark: abonelikler "non-consumable", kredi paketleri "consumable"
/// (buyConsumable) akışıyla satın alınıyor.
class CreditPurchaseService {
  CreditPurchaseService({required this.authService, required this.apiService});

  final AuthService authService;
  final SunoApiService apiService;

  // App Store Connect'te oluşturulan gerçek product ID'ler (henüz
  // oluşturulmadıysa bu ID'lerle oluşturulmalı — bkz. creditPackages.js).
  static const Set<String> productIds = {
    'com.melodia.app.credits.500',
    'com.melodia.app.credits.1000',
    'com.melodia.app.credits.3000',
    'com.melodia.app.credits.5000',
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final _statusController = StreamController<CreditPurchaseStatus>.broadcast();

  Stream<CreditPurchaseStatus> get statusStream => _statusController.stream;

  Future<List<ProductDetails>> loadProducts() async {
    if (kIsWeb) {
      throw Exception('Satın alma sadece iOS uygulamasında kullanılabilir, web\'de değil.');
    }
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
        'Kredi paketleri bulunamadı — App Store Connect\'teki ürünler henüz '
        'onaylanmamış/yayında olmayabilir, ya da Sandbox test hesabıyla '
        'giriş yapılmamış olabilir.',
      );
    }
    final order = productIds.toList();
    final sorted = [...response.productDetails]
      ..sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    return sorted;
  }

  void startListening() {
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _statusController.add(CreditPurchaseStatus.error('Satın alma hatası: $error'));
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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      purchaseParam = Sk2PurchaseParam(productDetails: product, applicationUserName: userId);
    } else {
      purchaseParam = PurchaseParam(productDetails: product);
    }

    // Kredi paketleri TÜKETİLEBİLİR -- abonelikteki buyNonConsumable
    // DEĞİL, buyConsumable kullanılıyor. Sonuç senkron dönmüyor, bkz.
    // _handlePurchaseUpdates.
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _statusController.add(CreditPurchaseStatus.pending());

        case PurchaseStatus.error:
          _statusController.add(
            CreditPurchaseStatus.error(purchase.error?.message ?? 'Satın alma başarısız oldu.'),
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

        case PurchaseStatus.canceled:
          _statusController.add(CreditPurchaseStatus.error('Satın alma iptal edildi.'));
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final signedTransactionInfo = purchase.verificationData.serverVerificationData;
            final bonusCredits = await apiService.verifyCreditPurchase(signedTransactionInfo);
            _statusController.add(CreditPurchaseStatus.success(bonusCredits: bonusCredits));
          } catch (e) {
            _statusController.add(CreditPurchaseStatus.error('Doğrulama başarısız: $e'));
          } finally {
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
          }
      }
    }
  }
}

enum CreditPurchaseStatusType { pending, success, error }

class CreditPurchaseStatus {
  CreditPurchaseStatus._(this.type, {this.message, this.bonusCredits});

  factory CreditPurchaseStatus.pending() => CreditPurchaseStatus._(CreditPurchaseStatusType.pending);

  factory CreditPurchaseStatus.success({int? bonusCredits}) =>
      CreditPurchaseStatus._(CreditPurchaseStatusType.success, bonusCredits: bonusCredits);

  factory CreditPurchaseStatus.error(String message) =>
      CreditPurchaseStatus._(CreditPurchaseStatusType.error, message: message);

  final CreditPurchaseStatusType type;
  final String? message;
  final int? bonusCredits;

  bool get isPending => type == CreditPurchaseStatusType.pending;
  bool get isSuccess => type == CreditPurchaseStatusType.success;
  bool get isError => type == CreditPurchaseStatusType.error;
}
