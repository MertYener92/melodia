import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/auth_service.dart';
import '../services/credit_purchase_service.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';

/// Tüketilebilir kredi paketi satın alma ekranı. paywall_screen.dart
/// (abonelik) ile AYNI desen -- tek fark: burada seçilen ürün "consumable"
/// akışıyla satın alınıyor ve başarı sonrası bonusCredits bakiyesi
/// güncelleniyor (abonelikte olduğu gibi plan değişmiyor).
class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key, required this.authService, required this.apiService});

  final AuthService authService;
  final SunoApiService apiService;

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  late final CreditPurchaseService _purchaseService;
  StreamSubscription<CreditPurchaseStatus>? _statusSubscription;

  List<ProductDetails> _products = [];
  ProductDetails? _selected;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _purchaseService = CreditPurchaseService(
      authService: widget.authService,
      apiService: widget.apiService,
    );
    _purchaseService.startListening();
    _statusSubscription = _purchaseService.statusStream.listen(_onStatus);
    _loadProducts();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _purchaseService.loadProducts();
      setState(() {
        _products = products;
        // Varsayılan seçili: 1000 (en dengeli seçenek)
        _selected = products.firstWhere(
          (p) => p.id.contains('1000'),
          orElse: () => products.first,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kredi paketleri yüklenemedi: $e';
        _loading = false;
      });
    }
  }

  void _onStatus(CreditPurchaseStatus status) {
    if (!mounted) return;
    if (status.isPending) {
      setState(() => _purchasing = true);
    } else if (status.isSuccess) {
      setState(() => _purchasing = false);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.bonusCredits != null
                ? 'Krediler eklendi! Toplam bakiyen: ${status.bonusCredits}'
                : 'Krediler hesabına eklendi.',
          ),
        ),
      );
    } else if (status.isError) {
      setState(() {
        _purchasing = false;
        _error = status.message;
      });
    }
  }

  Future<void> _purchase() async {
    final product = _selected;
    if (product == null) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      await _purchaseService.buy(product);
      // Sonuç statusStream üzerinden _onStatus'a gelecek.
    } catch (e) {
      setState(() {
        _purchasing = false;
        _error = 'Satın alma başlatılamadı: $e';
      });
    }
  }

  /// DÜZELTME: önceden `contains('.500')` ilk sırada kontrol ediliyordu --
  /// ".5000" ile biten ürün ID'si de ".500" İÇERDİĞİ için 5.000'lik paket
  /// ekranda "500 Kredi" görünüyordu. Artık ID'nin SONU eşleştiriliyor,
  /// büyükten küçüğe sıralama da gerekmiyor.
  String _creditsLabelFor(String productId) {
    const labels = {
      '5000': '5.000 Kredi',
      '3000': '3.000 Kredi',
      '1000': '1.000 Kredi',
      '500': '500 Kredi',
    };
    for (final entry in labels.entries) {
      if (productId.endsWith('.${entry.key}') || productId.endsWith(entry.key)) {
        return entry.value;
      }
    }
    return productId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kredi Al'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ekstra Kredi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Süresi dolmayan, tek seferlik kredi paketleri — abonelik kredi '
                    'havuzuna ek olarak kullanılır',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ),
                  ..._products.map((product) {
                    final isSelected = _selected?.id == product.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = product),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.purple : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.diamond_rounded, color: Color(0xFFF4B740), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _creditsLabelFor(product.id),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              product.price,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_purchasing || _selected == null) ? null : _purchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _purchasing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Satın Al',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Krediler süresiz kullanılabilir, iade edilemez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }
}
