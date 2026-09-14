import 'package:flutter/material.dart';
import '../services/song_library.dart';
import '../theme/app_theme.dart';

/// Suno'daki "generation kartı" mantığına benzer ama Melodia'nın kendi
/// premium tasarım diliyle: Şarkılarım listesinin İÇİNDE, normal bir
/// [SongTile] ile aynı satırda duran, devam eden bir üretimi gösteren
/// kart. Artık ayrı bir loading/progress SAYFASI YOK -- bu kart onun
/// yerini alıyor.
///
/// - Sol tarafta kare bir "artwork" alanı: gerçek artwork henüz yokken
///   uygulamanın gerçek Melodia ikonu (assets/icon/icon.png), koyu
///   lacivert/mor/magenta bir glassmorphism zemin üzerinde, hafif bir
///   nefes alma (pulse) animasyonuyla gösterilir.
/// - Kartın TAMAMI (arka plan + border) çok yavaş (~2.6sn) bir
///   navy → purple → magenta → navy döngüsüyle hafifçe parlar --
///   Suno'nun sert/hızlı yanıp sönmesinin AKSİNE sakin ve pahalı
///   hissettiren bir "breathing glow".
/// - Sağ tarafta üretim mesajı birkaç saniyede bir fade-out/fade-in ile
///   değişir; kartın tamamı yeniden inşa edilmez, sadece metin geçişi
///   olur.
/// - Üretim başarısız olursa kart sakin bir "hata" durumuna geçer ve
///   kullanıcı kartı kapatabilir ([onDismiss]).
class GenerationCard extends StatefulWidget {
  const GenerationCard({
    super.key,
    required this.librarySong,
    this.onDismiss,
  });

  final LibrarySong librarySong;

  /// Sadece başarısız üretimlerde gösterilen "kapat" aksiyonu.
  final VoidCallback? onDismiss;

  @override
  State<GenerationCard> createState() => _GenerationCardState();
}

class _GenerationCardState extends State<GenerationCard>
    with TickerProviderStateMixin {
  // Kartın tamamındaki "breathing glow" -- yavaş, sürekli, göz yormayan
  // bir döngü (~2.6sn gidiş + 2.6sn dönüş).
  late final AnimationController _glowController;

  // Üretim mesajları arasında geçiş için zamanlayıcı + fade kontrolü.
  late final AnimationController _textFadeController;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1,
    );

    _scheduleNextMessage();
  }

  void _scheduleNextMessage() {
    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted || !widget.librarySong.isGenerating) return;
      await _textFadeController.reverse(); // fade out
      if (!mounted) return;
      setState(() => _messageIndex++);
      await _textFadeController.forward(); // fade in
      _scheduleNextMessage();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  // Melodia'ya özgü, Suno'nun metinlerinin birebir kopyası OLMAYAN,
  // markanın diline uygun üretim mesajları. Uygulama dili TR/EN/ES
  // olabildiği için üçü de burada tutuluyor (mevcut generated
  // AppLocalizations dosyaları elle düzenlenmediği için -- kalıcı l10n
  // entegrasyonu istenirse bu liste ileride app_*.arb'a taşınabilir).
  static const Map<String, List<String>> _messages = {
    'tr': [
      'Melodini hazırlıyoruz…',
      'Ritimleri bir araya getiriyoruz…',
      'Sesler şekilleniyor…',
      'Vokaller üzerinde çalışıyoruz…',
      'Son dokunuşları yapıyoruz…',
      'Şarkın neredeyse hazır…',
    ],
    'en': [
      'Shaping your melody…',
      'Bringing the rhythm together…',
      'Sculpting the sound…',
      'Working on the vocals…',
      'Adding the final touches…',
      'Your song is almost ready…',
    ],
    'es': [
      'Dando forma a tu melodía…',
      'Uniendo el ritmo…',
      'Esculpiendo el sonido…',
      'Trabajando en las voces…',
      'Añadiendo los últimos detalles…',
      'Tu canción está casi lista…',
    ],
  };

  List<String> _messagesForLocale(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return _messages[code] ?? _messages['en']!;
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.librarySong;

    if (song.isFailedGeneration) {
      return _buildFailedCard(context);
    }

    final messages = _messagesForLocale(context);
    final message = messages[_messageIndex % messages.length];

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        // 0..1..0 arası yumuşak bir "breathing" eğrisi.
        final t = _glowController.value;
        final glow = 0.18 + (t * 0.22); // çok hafif -- sert flashing yok
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF14141F), AppColors.purpleDeep, t * 0.35)!,
                Color.lerp(AppColors.surface, AppColors.pink, t * 0.22)!,
              ],
            ),
            border: Border.all(
              color: Color.lerp(AppColors.border, AppColors.purple, t)!,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: glow * 0.6),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          _MelodiaPulseIcon(controller: _glowController),
          const SizedBox(width: 14),
          Expanded(
            child: FadeTransition(
              opacity: _textFadeController,
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.pink.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.pink,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.librarySong.errorMessage ?? 'Şarkı üretilemedi.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ),
          if (widget.onDismiss != null)
            IconButton(
              onPressed: widget.onDismiss,
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

/// Kartın sol tarafındaki kare artwork alanı: gerçek şarkı kapağı henüz
/// yokken uygulamanın GERÇEK Melodia ikonu, hafif nefes alan bir glow
/// içinde gösterilir. SAHTE/yeni bir logo ÜRETİLMEZ.
class _MelodiaPulseIcon extends StatelessWidget {
  const _MelodiaPulseIcon({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        // İkon çok hafif büyüyüp küçülüyor (pulse) -- ~%4 genlik.
        final scale = 1.0 + (t * 0.04);
        final glow = 0.25 + (t * 0.35);
        return Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF120B22),
                Color.lerp(AppColors.purpleDeep, AppColors.pink, t * 0.5)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pink.withValues(alpha: glow * 0.5),
                blurRadius: 16,
                spreadRadius: 0.5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(13),
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              'assets/icon/icon.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }
}