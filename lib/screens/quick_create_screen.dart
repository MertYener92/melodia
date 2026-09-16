import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../models/music_spec.dart';
import '../services/music_spec_service.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/mode_cost_badge.dart';
import '../widgets/provider_selector.dart';
import 'my_songs_screen.dart';

/// "Hızlı" modu: kullanıcı tek cümlede fikrini yazar, arka planda aynı
/// Bedrock yorumlama adımından geçer ama hiçbir soru sorulmaz — en az
/// sürtünmeli yol.
class QuickCreateScreen extends StatefulWidget {
  const QuickCreateScreen({
    super.key,
    required this.service,
    required this.musicSpecService,
    required this.library,
    required this.player,
  });

  final SunoApiService service;
  final MusicSpecService musicSpecService;
  final SongLibrary library;
  final PlayerController player;

  @override
  State<QuickCreateScreen> createState() => _QuickCreateScreenState();
}

class _QuickCreateScreenState extends State<QuickCreateScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  String _provider = 'suno';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    // DÜZELTME: hızlı art arda iki dokunuş (setState henüz butonu devre
    // dışı bırakmadan), _generate()'in iki kez çalışıp iki ayrı gerçek
    // şarkı isteği (= 2 jeton) oluşturmasına sebep olabiliyordu. Bu
    // senkron kontrol, ikinci dokunuşu setState'in bitmesini beklemeden
    // hemen engeller.
    if (_loading) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final MusicSpec spec = await widget.musicSpecService.interpret(
        answers: {'story': text, 'creative_direction': text},
        // DÜZELTME: Önceden sabit 'tr' idi -- uygulama başka bir dilde
        // (ör. İngilizce) kullanılırken bile yorumlama isteği Türkçe
        // gönderiliyordu. Artık o an aktif olan uygulama diline göre
        // gönderiliyor.
        language: Localizations.localeOf(context).languageCode,
      );

      if (!mounted) return;

      String vocalLabel;
      switch (spec.vocalGender) {
        case 'male':
          vocalLabel = 'Male';
        case 'female':
          vocalLabel = 'Female';
        case 'instrumental':
          vocalLabel = 'Instrumental';
        default:
          vocalLabel = 'Female';
      }
      final instrumental = vocalLabel == 'Instrumental';
      String? vocalGender;
      if (vocalLabel == 'Female') vocalGender = 'f';
      if (vocalLabel == 'Male') vocalGender = 'm';

      // DEĞİŞTİ: Artık ayrı bir GeneratingScreen'e push edip sonucu
      // BEKLEMİYORUZ. Üretim SongLibrary içinde arka planda başlar
      // (Şarkılarım listesinin en üstünde ANINDA bir generation card
      // belirir) ve kullanıcı hemen o ekrana yönlendirilir. Future'ı
      // burada bilerek await ETMİYORUZ (unawaited) -- SongLibrary tek
      // bir singleton olduğu için üretim, bu ekran kapansa bile arka
      // planda devam eder.
      unawaited(
        widget.library.startGeneration(
          prompt: spec.lyricalTheme.isNotEmpty ? spec.lyricalTheme : text,
          displayGenre: spec.genre,
          displayMood: spec.mood.isNotEmpty ? spec.mood.first : '',
          genre: spec.genre,
          mood: spec.mood.join(', '),
          vocalGender: vocalGender,
          instrumental: instrumental,
          durationSeconds: 120,
          styleOverride: spec.generationPrompt,
          titleOverride: spec.title,
          provider: _provider,
          lyricsLanguage: spec.lyricalLanguage,
          mode: 'quick',
        ),
      );

      if (!mounted) return;
      // Bu ekranı (ve üstündeki Hızlı formu) kapatıp doğrudan
      // Şarkılarım'a geçiyoruz -- HomeShell (ilk/tek kök rota) korunur,
      // sadece üretim formu route'ları temizlenir. Kullanıcı zaten
      // Şarkılarım'daysa (bu akışta mümkün değil, ama savunma amaçlı)
      // ikinci bir push oluşmaz çünkü zaten route yığını temizleniyor.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MySongsScreen(
            library: widget.library,
            player: widget.player,
          ),
        ),
        (route) => route.isFirst,
      );
    } on MusicSpecException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = l10n.unexpectedErrorWithDetail(e.toString());
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.modeQuickTitle)),
      body: Container(
        // DÜZELTME: Önceden AppColors.backgroundGlow (üstte mora çalan bir
        // gradyan) kullanılıyordu -- Standart ekran (create_form_screen.dart)
        // ise Scaffold'un düz siyah varsayılanını kullanıyordu. Bu, Hızlı
        // ekranın üstünün "siyah altı mavi/mor" gibi farklı görünmesine
        // sebep oluyordu. Artık üçü de (Hızlı/Standart/Gelişmiş) aynı düz
        // siyah arka planı kullanıyor.
        color: AppColors.background,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.pink, size: 34),
                const SizedBox(height: 14),
                Text(
                  l10n.quickCreateHeadline,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.quickCreateSubtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ProviderSelector(
                  value: _provider,
                  onChanged: _loading
                      ? (_) {}
                      : (v) => setState(() => _provider = v),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    maxLength: 300,
                    enabled: !_loading,
                    style: const TextStyle(color: AppColors.textPrimary),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l10n.quickCreateHint,
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      counterStyle: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.pink, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 20),
                const ModeCostBadge(credits: 10, songCount: 2),
                const SizedBox(height: 10),
                GradientButton(
                  label: _loading ? l10n.preparingLabel : l10n.actionCreate,
                  icon: Icons.auto_awesome_rounded,
                  isLoading: _loading,
                  onPressed: _controller.text.trim().isEmpty || _loading
                      ? null
                      : _generate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}