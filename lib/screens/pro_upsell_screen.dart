import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';

import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cinematic_video_hero.dart';

/// Otomatik açılan premium "PRO'ya geç" ekranı.
///
/// NOT: Bu, `paywall_screen.dart` (Ayarlar > Planı Yükselt'ten elle
/// açılan, 3 planı listeleyen ekran) ile AYNI ekran DEĞİL — bilinçli
/// olarak ayrı tutuldu. Bu ekran sadece 2 planı (haftalık + yıllık) öne
/// çıkaran, sinematik bir video hero'ya sahip, uygulama açılışında
/// otomatik gösterilen bir "upsell" ekranı. İkisi de aynı
/// [SubscriptionService]'i (mevcut StoreKit 2 altyapısı) kullanır —
/// yeni/ayrı bir satın alma sistemi KURULMADI.
class ProUpsellScreen extends StatefulWidget {
  const ProUpsellScreen({
    super.key,
    required this.authService,
    required this.apiService,
  });

  final AuthService authService;
  final SunoApiService apiService;

  @override
  State<ProUpsellScreen> createState() => _ProUpsellScreenState();
}

class _ProUpsellScreenState extends State<ProUpsellScreen> {
  late final SubscriptionService _subscriptionService;
  StreamSubscription<SubscriptionPurchaseStatus>? _statusSubscription;

  ProductDetails? _weekly;
  ProductDetails? _yearly;
  ProductDetails? _selected;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  // GEÇİCİ TEŞHİS ARAÇLARI -- "sonsuz kayma" hatasının gerçek sebebini
  // tahminle değil ÖLÇEREK bulmak için. Sorun çözülünce bu blok (ve
  // build()'deki _DebugOverlay çağrısı) TAMAMEN kaldırılacak.
  final _contentKey = GlobalKey();
  final _heroKey = GlobalKey();
  final _contentBoxKey = GlobalKey();
  final _scrollController = ScrollController();
  double? _measuredContentHeight;
  double? _measuredHeroHeight;
  double? _measuredContentBoxHeight;

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
    _scrollController.addListener(() {
      if (mounted) setState(() {}); // teşhis panelini canlı güncelle
    });
    WidgetsBinding.instance.addPostFrameCallback(_measureContent);
  }

  void _measureContent([_]) {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    final heroBox = _heroKey.currentContext?.findRenderObject() as RenderBox?;
    final contentBox = _contentBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (mounted) {
      setState(() {
        if (box != null) _measuredContentHeight = box.size.height;
        if (heroBox != null) _measuredHeroHeight = heroBox.size.height;
        if (contentBox != null) _measuredContentBoxHeight = contentBox.size.height;
      });
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _subscriptionService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _subscriptionService.loadProducts();
      final weekly = products.where((p) => p.id.contains('weekly')).firstOrNull;
      final yearly = products.where((p) => p.id.contains('yearly')).firstOrNull;
      if (!mounted) return;
      setState(() {
        _weekly = weekly;
        _yearly = yearly;
        // İSTENEN DAVRANIŞ: ekran ilk açıldığında yıllık paket varsayılan
        // seçili gelsin.
        _selected = yearly ?? weekly;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(_measureContent);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = l10n.productsLoadErrorWithDetail(e.toString());
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(_measureContent);
    }
  }

  void _onStatus(SubscriptionPurchaseStatus status) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (status.isPending) {
      setState(() => _purchasing = true);
    } else if (status.isSuccess) {
      setState(() => _purchasing = false);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.purchaseSuccessMessage)),
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      await _subscriptionService.buy(product);
      // Sonuç statusStream üzerinden _onStatus'a gelecek.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _purchasing = false;
        _error = l10n.purchaseStartErrorWithDetail(e.toString());
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
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _purchasing = false;
        _error = l10n.purchaseStartErrorWithDetail(e.toString());
      });
    }
  }

  /// Yıllık planın haftalık plana göre yüzde kaç tasarruf sağladığını
  /// hesaplar (52 hafta üzerinden). İkisinden biri eksikse null döner —
  /// UYDURMA bir yüzde GÖSTERİLMEZ.
  int? get _savingsPercent {
    final weekly = _weekly;
    final yearly = _yearly;
    if (weekly == null || yearly == null) return null;
    final weeklyAnnualCost = weekly.rawPrice * 52;
    if (weeklyAnnualCost <= 0) return null;
    final savings = 1 - (yearly.rawPrice / weeklyAnnualCost);
    if (savings <= 0) return null;
    return (savings * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.34;

    return Scaffold(
      backgroundColor: AppColors.background,
      // DÜZELTME (6. ve KESİN deneme): Önceki denemeler (Expanded ->
      // CustomScrollView/Sliver -> LayoutBuilder+ConstrainedBox) hep bir
      // ÜST SEVİYE mekanizmayı değiştiriyordu ama telefonda sorun sürdü.
      // Şüphelenilen son nokta: LayoutBuilder, bir Stack içinde GEVŞEK
      // (loose) constraint alıyordu -- bu zincirde "maxHeight" değerinin
      // beklenmedik şekilde bozulma ihtimaline karşı LayoutBuilder'ı
      // TAMAMEN kaldırdık. Artık MediaQuery'nin mutlak, hiçbir ata
      // widget'ın constraint zincirine bağlı OLMAYAN gerçek fiziksel ekran
      // yüksekliğini (screenHeight) SingleChildScrollView'ın tek çocuğuna
      // ConstrainedBox(minHeight: screenHeight) ile doğrudan veriyoruz +
      // fiziksel esnek geri sekmeyi (bounce) ClampingScrollPhysics ile
      // kapatıyoruz. Kaydırma, içerik nereye kadar varsa TAM ORADA sert
      // bir şekilde bitiyor; ötesine hiç geçilemiyor.
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: Column(
                    key: _contentKey,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        key: _heroKey,
                        height: heroHeight,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            CinematicVideoHero(
                              assetPath: 'assets/videos/pro_hero.mp4',
                              height: heroHeight,
                            ),
                            // Video -> arka plan geçişi: yumuşak, sert kenar yok.
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: heroHeight * 0.65,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0x991A1030),
                                      AppColors.background,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        key: _contentBoxKey,
                        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          28 + MediaQuery.of(context).padding.bottom,
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.proUpsellTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.proUpsellSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.purple),
                          ),
                        )
                      else ...[
                        if (_error != null) ...[
                          _ErrorBanner(message: _error!),
                          const SizedBox(height: 14),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_weekly != null)
                              Expanded(
                                child: _PlanCard(
                                  title: l10n.planWeeklyTitle,
                                  subtitle: l10n.planWeeklySubtitle,
                                  price: _weekly!.price,
                                  badge: null,
                                  isSelected: _selected?.id == _weekly!.id,
                                  onTap: () => setState(() => _selected = _weekly),
                                ),
                              ),
                            if (_weekly != null && _yearly != null)
                              const SizedBox(width: 12),
                            if (_yearly != null)
                              Expanded(
                                child: _PlanCard(
                                  title: l10n.planYearlyTitle,
                                  subtitle: l10n.planYearlyBadge,
                                  price: _yearly!.price,
                                  badge: _savingsPercent != null
                                      ? l10n.saveBadge(_savingsPercent!)
                                      : null,
                                  isSelected: _selected?.id == _yearly!.id,
                                  onTap: () => setState(() => _selected = _yearly),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _FeatureRow(icon: Icons.check_circle_rounded, text: l10n.featureSongsVideos),
                        const SizedBox(height: 12),
                        _FeatureRow(icon: Icons.check_circle_rounded, text: l10n.featureVoiceCovers),
                        const SizedBox(height: 12),
                        _FeatureRow(icon: Icons.check_circle_rounded, text: l10n.featurePriorityGeneration),
                        const SizedBox(height: 12),
                        _FeatureRow(icon: Icons.check_circle_rounded, text: l10n.featureCommercialLicense),
                        const SizedBox(height: 26),
                        _PrimaryCta(
                          label: l10n.ctaContinue,
                          isLoading: _purchasing,
                          onPressed: (_selected == null || _purchasing) ? null : _subscribe,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.cancelAnytimeNote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: _purchasing ? null : _restore,
                            child: Text(
                              l10n.restorePurchasesAction,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                    ],
                  ),
                ),
              ),

          // Kapatma butonu — kaydırılan alanın DIŞINDA, ayrı bir Stack
          // katmanında. Videonun üzerinde başlıyor ama kaydırma
          // içeriğinin bir parçası olmadığı için her zaman aynı yerde,
          // her zaman dokunulabilir kalıyor.
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _GlassCloseButton(onTap: () => Navigator.of(context).pop(false)),
          ),

          // GEÇİCİ TEŞHİS PANELİ -- sorun çözülünce kaldırılacak. Ekran
          // görüntüsü olarak paylaşılabilsin diye gerçek sayıları canlı
          // gösteriyor.
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: _DebugOverlay(
              screenHeight: screenHeight,
              heroHeight: heroHeight,
              measuredContentHeight: _measuredContentHeight,
              measuredHeroHeight: _measuredHeroHeight,
              measuredContentBoxHeight: _measuredContentBoxHeight,
              maxScrollExtent: _scrollController.hasClients
                  ? _scrollController.position.maxScrollExtent
                  : null,
              currentScrollPixels: _scrollController.hasClients
                  ? _scrollController.position.pixels
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// GEÇİCİ TEŞHİS WIDGET'I -- "sonsuz kayma" hatasının gerçek sebebini
/// tahminle değil ölçerek bulmak için eklendi. Sorun kesin olarak
/// çözülüp doğrulanınca bu class'ın TAMAMI (ve yukarıdaki çağrısı)
/// kaldırılacak.
class _DebugOverlay extends StatelessWidget {
  const _DebugOverlay({
    required this.screenHeight,
    required this.heroHeight,
    required this.measuredContentHeight,
    required this.measuredHeroHeight,
    required this.measuredContentBoxHeight,
    required this.maxScrollExtent,
    required this.currentScrollPixels,
  });

  final double screenHeight;
  final double heroHeight;
  final double? measuredContentHeight;
  final double? measuredHeroHeight;
  final double? measuredContentBoxHeight;
  final double? maxScrollExtent;
  final double? currentScrollPixels;

  @override
  Widget build(BuildContext context) {
    String fmt(double? v) => v == null ? '—' : v.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.greenAccent, width: 1),
      ),
      child: Text(
        'ekranH: ${fmt(screenHeight)}\n'
        'videoH(hedef): ${fmt(heroHeight)}\n'
        'videoH(olcum): ${fmt(measuredHeroHeight)}\n'
        'icerikKutuH: ${fmt(measuredContentBoxHeight)}\n'
        'toplamH: ${fmt(measuredContentHeight)}\n'
        'maxScroll: ${fmt(maxScrollExtent)}\n'
        'kaydirma: ${fmt(currentScrollPixels)}',
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 11,
          fontFamily: 'monospace',
          height: 1.4,
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.badge,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceElevated.withValues(alpha: 0.9)
              : AppColors.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.pink : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.pink.withValues(alpha: 0.28),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
            ),
            const SizedBox(height: 14),
            Text(
              price,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.isLoading, required this.onPressed});
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null
            : AppColors.primaryGradient,
        color: onPressed == null ? AppColors.surfaceElevated : null,
        borderRadius: BorderRadius.circular(999),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: AppColors.pink.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _GlassCloseButton extends StatelessWidget {
  const _GlassCloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.black.withValues(alpha: 0.32),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 19),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}