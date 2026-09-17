import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/locale_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_border_painter.dart';
import 'account_info_screen.dart';
import 'credits_screen.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';

/// DEĞİŞTİ (tam yeniden tasarım): kullanıcının verdiği referans görsele
/// BİREBİR göre yeniden yapıldı -- üstte başlık+ayarlar, avatar+plan
/// rozeti+üyelik tarihi, iki istatistik kartı, "Kalan Jeton" kartı
/// (Kredi Al butonuyla), "Planın" kartı (Planı Yönet butonuyla,
/// özellik ikonları), ve alt menü listesi.
///
/// NOT (görselle tek fark): referans görselde ikinci istatistik kartı
/// "Favorites" -- daha önceki bir konuşmada bunun yerine "Videos"
/// istenmişti ama bu turda "görseldeki gibi birebir" istendiği için
/// BİREBİR Favorites olarak bırakıldı. Video sayısına geçmek istenirse
/// tek satırlık bir değişiklik.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.library,
    required this.service,
    required this.authService,
    required this.localeController,
    required this.onLoggedOut,
  });

  final SongLibrary library;
  final SunoApiService service;
  final AuthService authService;
  final LocaleController localeController;

  /// Çıkış yapıldığında ya da hesap silindiğinde çağrılır (main.dart'a
  /// kadar bubbling yaparak login ekranına dönmeyi sağlar).
  final VoidCallback onLoggedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran her açıldığında en taze plan/jeton/üyelik bilgisini çek --
    // SongLibrary zaten bu veriyi tutuyor (bkz. refreshQuota), burada
    // sadece kesinlikle güncel olduğundan emin oluyoruz.
    widget.library.refreshQuota();
  }

  String get _displayName {
    final email = widget.authService.email;
    if (email == null || email.isEmpty) return 'Kullanıcı';
    // NOT: Cognito/Apple'da ayrı bir "ad soyad" alanı tutulmuyor (sadece
    // e-posta) -- e-postanın @ öncesi kısmından, kabaca okunabilir bir
    // görünen ad türetiliyor. Gerçek bir "ad" alanı istenirse bu, ayrı
    // bir backend + profil düzenleme ekranı gerektirir.
    final localPart = email.split('@').first;
    final cleaned = localPart.replaceAll(RegExp(r'[._]+'), ' ').trim();
    if (cleaned.isEmpty) return 'Kullanıcı';
    return cleaned
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _planLabelFor(String plan) {
    switch (plan) {
      case 'pro_weekly':
        return 'Pro • Haftalık Plan';
      case 'pro_monthly':
        return 'Pro • Aylık Plan';
      case 'pro_yearly':
        return 'Pro • Yıllık Plan';
      default:
        return 'Ücretsiz Plan';
    }
  }

  String _planTitleFor(String plan) {
    switch (plan) {
      case 'pro_weekly':
        return 'Pro - Haftalık';
      case 'pro_monthly':
        return 'Pro - Aylık';
      case 'pro_yearly':
        return 'Pro - Yıllık';
      default:
        return 'Ücretsiz';
    }
  }

  String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final date = DateTime.tryParse(iso);
    if (date == null) return null;
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: ListenableBuilder(
        listenable: widget.library,
        builder: (context, _) {
          final plan = widget.library.plan ?? 'free';
          final isPro = widget.library.isPro;
          final remaining = widget.library.remainingCredits;
          final bonus = widget.library.bonusCredits;
          // "limit"i /quota'nın kendisi döndürmüyor (sadece remaining) --
          // ekranda "kullanılan/limit" göstermek için remaining ile
          // birlikte quotaError olmadığını bildiğimiz anda elimizdeki
          // TEK güvenilir sayı remaining -- bu yüzden "X jeton kaldı"
          // şeklinde, referans görseldeki "475/500" yerine daha basit
          // ama HER ZAMAN doğru bir gösterim kullanılıyor.
          final memberSince = _formatDate(widget.library.memberSince);
          final renewsOn = _formatDate(widget.library.planExpiresAt);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              // ---- Başlık + Ayarlar ----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profilin',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yarat. Hayal Et. Her Yerde Dinle.',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          service: widget.service,
                          authService: widget.authService,
                          localeController: widget.localeController,
                          onAccountDeleted: widget.onLoggedOut,
                        ),
                      ),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---- Avatar + isim + plan rozeti + üyelik tarihi ----
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(100, 100),
                            painter: const GradientBorderPainter(
                              gradient: AppColors.goldGradient,
                              borderRadius: 50,
                              strokeWidth: 2.2,
                            ),
                          ),
                          Container(
                            width: 84,
                            height: 84,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // NOT: fotoğraf yükleme/düzenleme özelliği henüz YOK --
                    // bu ikon referans görseldeki gibi duruyor ama şimdilik
                    // dokununca hiçbir şey yapmıyor (ileride profil fotoğrafı
                    // eklenince buraya bağlanacak).
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: AppColors.textSecondary, size: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: isPro ? AppColors.goldGradient : null,
                    color: isPro ? null : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(999),
                    border: isPro ? null : Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPro) ...[
                        const Icon(Icons.workspace_premium_rounded, size: 13, color: Colors.black87),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        _planLabelFor(plan),
                        style: TextStyle(
                          color: isPro ? Colors.black.withValues(alpha: 0.85) : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (memberSince != null) ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Üyelik: $memberSince',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ---- Kalan Jeton kartı ----
              // DÜZELTME: free plan kullanıcısında bu kart TAMAMEN
              // gizleniyor (önceden "—" gibi anlamsız bir değer
              // gösteriyordu) -- sadece Pro kullanıcılarda görünür.
              if (isPro) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppColors.glassCard(radius: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            // DÜZELTME: dolar ikonu yerine bakiye/cüzdan
                            // tarzı bir ikon.
                            child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.purple, size: 19),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Kalan Jeton',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (_) => CreditsScreen(
                                    authService: widget.authService,
                                    apiService: widget.service,
                                  ),
                                ),
                              );
                              widget.library.refreshQuota();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'Kredi Al',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        remaining != null ? '${remaining + bonus}' : '—',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (bonus > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$remaining abonelik + $bonus satın alınan jeton',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                        ),
                      ],
                      if (renewsOn != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Yenilenme: $renewsOn',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ---- Plan kartı ----
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppColors.glassCard(radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: Colors.black87, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Planın',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _planTitleFor(plan),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PaywallScreen(
                                  authService: widget.authService,
                                  apiService: widget.service,
                                ),
                              ),
                            );
                            widget.library.refreshQuota();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Planı Yönet',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPro ? 'Tüm özelliklere tam erişim' : 'Sınırlı özellikler — Pro\'ya geç',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    // NOT: bu 3 özellik pazarlama amaçlı, referans görselle
                    // BİREBİR -- "Ses Klonlama" (Voice Cloning) henüz
                    // GERÇEKTEN inşa edilmedi (proje backlog'unda), bu
                    // satır şimdilik özlem/gelecek vaadi olarak duruyor.
                    // DÜZELTME: "Sınırsız Üretim" kaldırıldı (dar
                    // ekranlarda satıra sığmayıp taşıyordu), kalan 3
                    // ortalanmış şekilde diziliyor.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _FeatureChip(
                          // DÜZELTME: Unicode sembol (♫) fontlara göre çok
                          // ince/tutarsız görünüyordu -- gerçek bir Material
                          // ikonuna (library_music, zaten çift-nota şeklinde
                          // çizilmiş bir ikon) geçildi, cihazdan bağımsız
                          // her zaman aynı, kalın görünür.
                          icon: Icon(Icons.library_music_rounded, color: AppColors.purple, size: 16),
                          label: 'Yüksek\nKalite Ses',
                        ),
                        SizedBox(width: 18),
                        _FeatureChip(
                          icon: Icon(Icons.movie_creation_rounded, color: AppColors.purple, size: 15),
                          label: 'AI Video\nÜretimi',
                        ),
                        SizedBox(width: 18),
                        _FeatureChip(
                          icon: Icon(Icons.graphic_eq_rounded, color: AppColors.purple, size: 15),
                          label: 'Ses\nKlonlama',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---- Menü listesi (TEK kart, aralarında ince ayırıcı) ----
              // DÜZELTME: önceden her satır AYRI bir glassCard kutusuydu
              // (görünür boşluklarla) -- referans görselde tek, sürekli
              // bir kart var, satırlar sadece ince bir çizgiyle ayrılıyor.
              Container(
                decoration: AppColors.glassCard(radius: 16),
                // ClipRRect: içindeki ListTile'ların dokunma efekti
                // (InkWell) dış kartın yuvarlak köşelerinin dışına
                // taşmasın diye -- tüm sütun TEK seferde kırpılıyor,
                // her satırı ayrı ayrı işlemeye gerek yok.
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                    _MenuTile(
                      icon: Icons.person_outline,
                      label: 'Hesap Bilgileri',
                      subtitle: 'E-posta, şifre ve kişisel bilgiler',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AccountInfoScreen(
                            authService: widget.authService,
                            library: widget.library,
                          ),
                        ),
                      ),
                    ),
                    const _MenuDivider(),
                    _MenuTile(
                      icon: Icons.credit_card_outlined,
                      label: 'Abonelik ve Ödeme',
                      subtitle: 'Plan detayları, ödeme geçmişi, faturalar',
                      // NOT: ayrı bir "ödeme geçmişi/fatura" ekranı YOK --
                      // Apple zaten bunu App Store'un kendi abonelik
                      // yönetim ekranında tutuyor, bu yüzden en yakın
                      // karşılığı olan PaywallScreen'e yönlendiriliyor.
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaywallScreen(
                              authService: widget.authService,
                              apiService: widget.service,
                            ),
                          ),
                        );
                        widget.library.refreshQuota();
                      },
                    ),
                    const _MenuDivider(),
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      label: l10n.profileSettings,
                      subtitle: 'Uygulama tercihleri, bildirimler, dil',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            service: widget.service,
                            authService: widget.authService,
                            localeController: widget.localeController,
                            onAccountDeleted: widget.onLoggedOut,
                          ),
                        ),
                      ),
                    ),
                    const _MenuDivider(),
                    _MenuTile(
                      icon: Icons.help_outline,
                      label: l10n.profileHelpSupport,
                      subtitle: 'SSS, bize ulaşın, sorun bildirin',
                      // NOT: ayrı bir destek ekranı YOK -- dokununca
                      // şimdilik hiçbir şey açılmıyor.
                    ),
                    const _MenuDivider(),
                    _MenuTile(
                      icon: Icons.info_outline,
                      label: l10n.profileAboutApp,
                      subtitle: 'Sürüm 1.0.0',
                      // NOT: sürüm numarası şimdilik sabit yazılı --
                      // pubspec.yaml ile senkron tutmak istenirse
                      // package_info_plus paketiyle dinamik okunabilir.
                    ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// DÜZELTME: ikon-üstte/yazı-altta dikey düzen yerine, referans görsele
/// göre ikon (solda, renkli daire içinde) + iki satırlık yazı (sağda,
/// sola hizalı) yatay düzen.
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: icon,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap ?? () {},
    );
  }
}

/// Menü kartındaki satırlar arasında ince ayırıcı çizgi -- referans
/// görseldeki gibi, ikonun hizasından değil baştan başlıyor.
class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.border);
  }
}
