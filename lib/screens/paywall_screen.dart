import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    super.key,
    required this.authService,
    required this.apiService,
  });

  final AuthService authService;
  final SunoApiService apiService;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late final SubscriptionService _subscriptionService;
  StreamSubscription<SubscriptionPurchaseStatus>? _statusSubscription;

  List<ProductDetails> _products = [];
  ProductDetails? _selected;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService(
      authService: widget.authService,
      apiService: widget.apiService,
    );
    _subscriptionService.startListening();
    _statusSubscription = _subscriptionService.statusStream.listen(_onStatus);
    _loadProducts();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _subscriptionService.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _subscriptionService.loadProducts();
      setState(() {
        _products = products;
        // Varsayılan seçili: monthly (en dengeli seçenek)
        _selected = products.firstWhere(
          (p) => p.id.contains('monthly'),
          orElse: () => products.first,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ürünler yüklenemedi: $e';
        _loading = false;
      });
    }
  }

  void _onStatus(SubscriptionPurchaseStatus status) {
    if (!mounted) return;
    if (status.isPending) {
      setState(() => _purchasing = true);
    } else if (status.isSuccess) {
      setState(() => _purchasing = false);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aboneliğin aktif! Pro\'ya hoş geldin.')),
      );
    } else if (status.isError) {
      setState(() {
        _purchasing = false;
        _error = status.message;
      });
    }
  }

  Future<void> _subscribe() async {
    final product = _selected;
    if (product == null) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      await _subscriptionService.buy(product);
      // Sonuç statusStream üzerinden _onStatus'a gelecek.
    } catch (e) {
      setState(() {
        _purchasing = false;
        _error = 'Satın alma başlatılamadı: $e';
      });
    }
  }

  Future<void> _restore() async {
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      await _subscriptionService.restorePurchases();
    } catch (e) {
      setState(() {
        _purchasing = false;
        _error = 'Geri yükleme başarısız: $e';
      });
    }
  }

  String _labelFor(String productId) {
    if (productId.contains('weekly')) return 'Haftalık';
    if (productId.contains('yearly')) return 'Yıllık';
    return 'Aylık';
  }

  String _subtitleFor(String productId) {
    if (productId.contains('weekly')) return '25 jeton, haftalık faturalandırılır';
    if (productId.contains('yearly')) return '120 jeton/ay, yıllık faturalandırılır';
    return '120 jeton, aylık faturalandırılır';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Melodia Pro'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              )
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
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Melodia Pro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sınırsız yaratıcılık için aylık jeton havuzuna sahip ol',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
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
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ..._products.map((product) {
                    final isSelected = _selected?.id == product.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = product),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.purple
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _labelFor(product.id),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _subtitleFor(product.id),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                      onPressed: (_purchasing || _selected == null)
                          ? null
                          : _subscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        disabledBackgroundColor: AppColors.purple.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _purchasing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Devam et',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _purchasing ? null : _restore,
                      child: const Text(
                        'Satın alımları geri yükle',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Abonelik otomatik yenilenir, istediğin zaman '
                    'App Store ayarlarından iptal edebilirsin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }
}