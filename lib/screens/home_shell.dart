import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/locale_controller.dart';
import '../services/music_spec_service.dart';
import '../services/music_video_service.dart';
import '../services/player_controller.dart';
import '../services/pro_screen_session_gate.dart';
import '../services/song_library.dart';
import '../services/subscription_products_cache.dart';
import '../services/subscription_service.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/premium_bottom_nav.dart';
import 'create_screen.dart';
import 'credits_screen.dart';
import 'ai_video_screen.dart';
import 'library_screen.dart';
import 'player_screen.dart';
import 'pro_upsell_screen.dart';
import 'profile_screen.dart';

/// Bottom navigation bar ile AI Müzik / My Songs / Kütüphane / Profile
/// sekmelerini bir arada tutan ana kabuk widget'ı.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.service,
    required this.musicSpecService,
    required this.musicVideoService,
    required this.authService,
    required this.localeController,
    required this.onLoggedOut,
  });

  final SunoApiService service;
  final MusicSpecService musicSpecService;
  final MusicVideoService musicVideoService;
  final AuthService authService;
  final LocaleController localeController;

  /// Çıkış yapıldığında ya da hesap silindiğinde çağrılır (login
  /// ekranına dönmek için).
  final VoidCallback onLoggedOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final SongLibrary _library;
  late final PlayerController _player;
  bool _imagesPrecached = false;
  Timer? _proUpsellTimer;

  @override
  void initState() {
    super.initState();
    _library = SongLibrary(service: widget.service);
    _library.loadFromBackend();
    // YENİ (ÇİFT JETON DÜŞME HATASININ DÜZELTMESİ): uygulama açılışında,
    // yarım kalmış (daha önce ödenmiş) bir üretim varsa YENİ bir istek
    // atmadan onu geri bulur -- bkz. song_library.dart.
    _library.resumePendingGenerationIfAny();
    // Sonraki/önceki sırası = kütüphanedeki şarkı listesi.
    _player = PlayerController(
      service: widget.service,
      queueSource: () => _library.songs,
    );
    _scheduleProUpsell();
    // YENİ (Pro ekranı yükleme kayması düzeltmesi): PRO ekranı en erken
    // 9sn sonra otomatik açılabiliyor -- bu süreyi, Apple'dan ürün
    // bilgilerini ARKA PLANDA önceden çekmek için kullanıyoruz. Ekran
    // gerçekten açıldığında (SubscriptionProductsCache doluysa) hiçbir
    // yükleme göstergesi görünmeden doğrudan fiyatlarla açılır.
    SubscriptionProductsCache.prefetch(
      SubscriptionService(authService: widget.authService, apiService: widget.service),
    );
  }

  /// İSTENEN DAVRANIŞ: uygulama açıldıktan 9 saniye sonra (splash video
  /// ~4sn + bu 9sn = kullanıcı ikona bastıktan sonra toplam ~13sn), bu
  /// UYGULAMA OTURUMU içinde daha önce hiç gösterilmediyse VE kullanıcı
  /// zaten Pro değilse, PRO ekranı otomatik açılır. "Gösterildi" bilgisi
  /// kalıcı olarak KAYDEDİLMEZ (bkz. ProScreenSessionGate) — sadece
  /// bellekte tutulur, uygulama tamamen kapat-aç yapılınca sıfırlanır.
  void _scheduleProUpsell() {
    if (ProScreenSessionGate.shownThisSession) return;
    _proUpsellTimer = Timer(const Duration(seconds: 9), () async {
      if (!mounted || ProScreenSessionGate.shownThisSession) return;

      // Kullanıcı zaten Pro'ysa (aktif abonelik) upsell ekranını hiç
      // gösterme. Mevcut jeton/plan sorgusunu (getQuota) kullanıyoruz —
      // ayrı bir "isPro" mekanizması icat etmiyoruz.
      bool isAlreadyPro = false;
      try {
        final quota = await widget.service.getQuota();
        isAlreadyPro = quota.plan.startsWith('pro_');
      } catch (_) {
        // Sorgu başarısız olursa temkinli davran: upsell'i YİNE DE
        // göster (yanlışlıkla bir Pro kullanıcıya göstermekten daha
        // az sakıncalı; kullanıcı zaten Pro'ysa satın alma ekranında
        // bunu App Store kendi tarafında zaten engeller).
      }
      if (!mounted || isAlreadyPro) return;

      ProScreenSessionGate.shownThisSession = true;
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProUpsellScreen(
            authService: widget.authService,
            apiService: widget.service,
          ),
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // DÜZELTME ("premium hissi" sorunu): Kütüphane sekmesindeki arka
    // plan görselleri (AssetImage) daha önce SADECE o sekmeye ilk kez
    // gidildiğinde decode ediliyordu -- bu da görsellerin ~1 saniye
    // gecikmeyle "pat" diye belirmesine (pop-in) sebep oluyordu. Burada
    // uygulama İLK AÇILDIĞI ANDA (hangi sekmede olursa olsun), bu dört
    // görseli arka planda önceden decode ediyoruz. Kullanıcı Kütüphane'ye
    // geçtiğinde görseller zaten Flutter'ın global image cache'inde
    // hazır bulunuyor, anında ve pürüzsüz görünüyor.
    if (!_imagesPrecached) {
      _imagesPrecached = true;
      for (final path in const [
        'assets/images/library_songs.png',
        'assets/images/library_videos.png',
        'assets/images/library_favorites.png',
        'assets/images/library_downloads.png',
      ]) {
        precacheImage(AssetImage(path), context);
      }
    }
  }

  @override
  void dispose() {
    _proUpsellTimer?.cancel();
    _player.dispose();
    _library.dispose();
    super.dispose();
  }

  void _goToTab(int index) => setState(() => _index = index);

  /// Remix başlayınca "Görüntüle": açık player'ı (ve varsa üstündeki
  /// sayfaları) kapatıp Kütüphane sekmesine geçer.
  void _openLibraryFromPlayer() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _goToTab(2);
  }

  /// Jeton yetmediğinde: Pro kullanıcıya jeton paketleri, diğerlerine Pro
  /// ekranı (Create ekranındaki rozetle aynı kural).
  void _openCreditsOrPro() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _library.isPro
            ? CreditsScreen(authService: widget.authService, apiService: widget.service)
            : ProUpsellScreen(authService: widget.authService, apiService: widget.service),
      ),
    );
  }

  /// Mini player -> tam ekran. Sayfa hafifçe yukarı kayıp belirirken kapak
  /// görseli (Hero) mini player'daki yerinden büyüyerek gelir.
  void _openPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => PlayerScreen(
          controller: _player,
          library: _library,
          service: widget.service,
          musicVideoService: widget.musicVideoService,
          onOpenLibrary: _openLibraryFromPlayer,
          onBuyCredits: _openCreditsOrPro,
        ),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screens = [
      CreateScreen(
        service: widget.service,
        musicSpecService: widget.musicSpecService,
        library: _library,
        player: _player,
        isActive: _index == 0,
        authService: widget.authService,
      ),
      AiVideoScreen(
        service: widget.musicVideoService,
        authService: widget.authService,
        apiService: widget.service,
        library: _library,
      ),
      LibraryScreen(
        songLibrary: _library,
        player: _player,
        videoService: widget.musicVideoService,
      ),
      ProfileScreen(
        library: _library,
        service: widget.service,
        authService: widget.authService,
        localeController: widget.localeController,
        onLoggedOut: widget.onLoggedOut,
        player: _player,
        onNavigateToCreate: () => _goToTab(0),
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: IndexedStack(index: _index, children: screens),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DEĞİŞTİ: mini player artık opak alt çubuğun DIŞINDA -- extendBody
          // sayesinde listenin üzerinde, yarı saydam/bulanık yüzeyiyle
          // içerikle bütünleşik görünüyor. Scaffold alt boşluğu (mini player
          // + nav yüksekliği) body'ye padding olarak verdiği için liste
          // içeriği yine de altında kaybolmuyor.
          ListenableBuilder(
            listenable: _player,
            builder: (context, _) => MiniPlayerBar(
              controller: _player,
              onTap: _openPlayer,
            ),
          ),
          Container(
            // DÜZELTME: extendBody:true olduğu için body (video/arka plan)
            // bottomNavigationBar'ın ARKASINA kadar uzanıyor. Rengi
            // SafeArea'nın DIŞINA sarıyoruz ki alt sistem boşluğu (home
            // indicator alanı) da kaplansın.
            color: AppColors.background,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: PremiumBottomNav(
                  currentIndex: _index,
                  onTap: _goToTab,
                  items: [
                    NavItemData(icon: Icons.home_rounded, label: l10n.navAiMusic),
                    NavItemData(
                      icon: Icons.movie_creation_rounded,
                      label: l10n.navAiVideo,
                    ),
                    NavItemData(icon: Icons.video_library_rounded, label: l10n.navLibrary),
                    NavItemData(icon: Icons.person_rounded, label: l10n.navProfile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} // 