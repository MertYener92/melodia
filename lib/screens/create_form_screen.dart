import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodia/l10n/generated/app_localizations.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../services/app_navigation.dart';
import '../theme/app_theme.dart';
import '../widgets/chip_group.dart';
import '../widgets/gradient_button.dart';
import '../widgets/mode_cost_badge.dart';
import '../widgets/provider_selector.dart';
import '../widgets/app_notice.dart';
import 'my_songs_screen.dart';

/// Şarkı üretim formu: prompt, genre/mood/vocal/length seçimleri ve
/// "Generate Song" akışı. Bu ekran, yeni video-hero [CreateScreen]'in
/// "Generate Song" CTA'sına basıldığında açılır. İşlevsellik (Suno API
/// çağrısı, kütüphaneye ekleme vb.) eski CreateScreen ile birebir aynı,
/// sadece ayrı bir route olarak taşındı.
class CreateFormScreen extends StatefulWidget {
  const CreateFormScreen({
    super.key,
    required this.service,
    required this.library,
    required this.player,
  });

  final SunoApiService service;
  final SongLibrary library;
  final PlayerController player;

  @override
  State<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {
  final TextEditingController _promptController = TextEditingController();

  static const _genres = ['Pop', 'Rock', 'Hip-Hop', 'EDM', 'R&B', 'Acoustic'];
  static const _moods = ['Happy', 'Chill', 'Energetic', 'Sad', 'Romantic'];
  static const _vocals = ['Female', 'Male', 'Instrumental'];
  static const _lengths = ['Short', 'Medium', 'Long'];

  String _genre = _genres.first;
  String _mood = _moods.first;
  String _vocal = _vocals.first;
  String _length = _lengths[1];

  // DÜZELTME: bu ekranda daha önce HİÇ bir gönderim koruması yoktu --
  // "Generate Song"a art arda iki kez basmak (ya da tek bir dokunuşun
  // donanım/render gecikmesiyle iki kez tetiklenmesi) iki ayrı gerçek
  // şarkı isteği (= 2 jeton) oluşturabiliyordu. Bu bayrak, buton devre
  // dışı kalana kadarki senkron pencereyi de kapatır.
  bool _submitting = false;
  String _provider = 'suno';

  static const Map<String, int> _lengthToSeconds = {
    'Short': 30,
    'Medium': 90,
    'Long': 180,
  };

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_submitting) return;

    final l10n = AppLocalizations.of(context)!;
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      AppNotice.show(context, l10n.describeSongFirst, type: NoticeType.warning);
      return;
    }

    setState(() => _submitting = true);

    final instrumental = _vocal == 'Instrumental';
    String? vocalGender;
    if (_vocal == 'Female') vocalGender = 'f';
    if (_vocal == 'Male') vocalGender = 'm';

    // DEĞİŞTİ: Artık ayrı bir GeneratingScreen'e push edip sonucu
    // BEKLEMİYORUZ. Üretim SongLibrary içinde arka planda başlar
    // (Şarkılarım listesinin en üstünde ANINDA bir generation card
    // belirir) ve kullanıcı hemen o ekrana yönlendirilir.
    unawaited(
      widget.library.startGeneration(
        prompt: prompt,
        displayGenre: _genre,
        displayMood: _mood,
        genre: _genre,
        mood: _mood,
        vocalGender: vocalGender,
        instrumental: instrumental,
        durationSeconds: _lengthToSeconds[_length] ?? 90,
        provider: _provider,
        lyricsLanguage: Localizations.localeOf(context).languageCode,
        mode: 'standard',
      ),
    );

    if (!mounted) return;
    // DEĞİŞTİ: üretim kartı artık Kütüphane SEKMESİNDE gösteriliyor (alt
    // sekmeler + mini player görünür); HomeShell yoksa eski sayfaya düş.
    if (AppNavigation.showLibrary(context)) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MySongsScreen(
          library: widget.library,
          player: widget.player,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createFormAppBarTitle)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.createFormHeadline,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.createFormSubtitle,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 22),
              _buildPromptCard(l10n),
              const SizedBox(height: 22),
              ChipGroup(
                label: l10n.labelGenre,
                options: _genres,
                selected: _genre,
                onSelected: (v) => setState(() => _genre = v),
              ),
              const SizedBox(height: 18),
              ChipGroup(
                label: l10n.labelMood,
                options: _moods,
                selected: _mood,
                onSelected: (v) => setState(() => _mood = v),
              ),
              const SizedBox(height: 18),
              ChipGroup(
                label: l10n.labelVocal,
                options: _vocals,
                selected: _vocal,
                onSelected: (v) => setState(() => _vocal = v),
              ),
              const SizedBox(height: 18),
              ChipGroup(
                label: l10n.labelSongLength,
                options: _lengths,
                selected: _length,
                onSelected: (v) => setState(() => _length = v),
              ),
              const SizedBox(height: 18),
              ProviderSelector(
                value: _provider,
                onChanged: _submitting
                    ? (_) {}
                    : (v) => setState(() => _provider = v),
              ),
              const SizedBox(height: 28),
              const ModeCostBadge(credits: 10, songCount: 2),
              const SizedBox(height: 10),
              GradientButton(
                label: l10n.createButton,
                icon: Icons.auto_awesome,
                isLoading: _submitting,
                onPressed: _submitting ? null : _generate,
                height: 58,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.describeSongLabel,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _promptController,
            minLines: 4,
            maxLines: 10,
            maxLength: kSongPromptMaxLength,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.describeSongHint,
              counterStyle: const TextStyle(color: AppColors.textMuted),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              suffixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 40, right: 4),
                child: Icon(Icons.auto_fix_high, color: AppColors.purple),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}