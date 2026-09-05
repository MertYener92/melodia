import 'package:flutter/material.dart';
import '../models/music_spec.dart';
import '../services/music_spec_service.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chip_multi_group.dart';
import '../widgets/gradient_button.dart';
import 'generating_screen.dart';

const String _worldCustomOption = 'Kendi fikrimi yazacağım';

const List<String> _worldOptions = [
  'Gece şehrin içinde',
  'Gün batımında sahilde',
  'Kalabalık bir kulüpte',
  'Uzun bir yolculukta',
  'Yağmurlu bir gecede',
  'Yazlık bir akşamda',
  'Tamamen başka bir dünyada',
  _worldCustomOption,
];

const List<String> _emotionOptions = [
  'İlk saniyede yakalasın',
  'İçine çeksin',
  'Kendini güçlü hissettirsin',
  'Aşık olmuş gibi hissettirsin',
  'Geceye karıştırsın',
  'Dans ettirsin',
  'Biraz hüzünlendirsin',
  'Tüyleri diken diken etsin',
];

const List<String> _movementOptions = [
  'Yavaş başlayıp patlasın',
  'Baştan sona enerjik',
  'Sakin başlayıp giderek büyüsün',
  'Dalgalı ve sürprizli',
  'Gece boyunca akıp gitsin',
  'Kısa ve vurucu',
];

const List<String> _soundOptions = [
  'Derin bas',
  'Parlak synth\'ler',
  'Kirli gitarlar',
  'Akustik dokunuşlar',
  'Büyük davullar',
  'Elektronik ritimler',
  'Piyano',
  'Yaylılar',
  'Atmosferik sesler',
  'Retro dokular',
];

const List<String> _vocalCharacterOptions = [
  'Güçlü ve karizmatik',
  'Yumuşak ve duygusal',
  'Karanlık ve gizemli',
  'Genç ve enerjik',
  'Sıcak ve samimi',
  'Sert ve asi',
  'Havalı ve mesafeli',
  'Rastgele',
];

const List<String> _vocalGenderOptions = ['Kadın', 'Erkek', 'Düet', 'Enstrümantal'];

const List<String> _chorusOptions = [
  'Dilime takılsın',
  'Büyük ve patlayıcı olsun',
  'Duygusal olsun',
  'Seyirci hep birlikte söyleyebilsin',
  'Karanlık ve akılda kalıcı olsun',
  'Kısa ama çok vurucu olsun',
];

const String _lyricsAi = 'AI tamamen yazsın';
const String _lyricsFromIdea = 'Fikrimden yola çıkarak yazsın';
const String _lyricsOwnFull = 'Ben sözleri vereceğim';
const String _lyricsOwnChorus = 'Ben sadece nakaratı vereceğim';
const List<String> _lyricsModeOptions = [
  _lyricsAi,
  _lyricsFromIdea,
  _lyricsOwnFull,
  _lyricsOwnChorus,
];

class MusicWizardScreen extends StatefulWidget {
  const MusicWizardScreen({
    super.key,
    required this.service,
    required this.musicSpecService,
    required this.library,
  });

  final SunoApiService service;
  final MusicSpecService musicSpecService;
  final SongLibrary library;

  @override
  State<MusicWizardScreen> createState() => _MusicWizardScreenState();
}

class _MusicWizardScreenState extends State<MusicWizardScreen> {
  // 0 = intro, 1..8 = sorular, 9 = özet
  static const int _totalSteps = 10;
  int _step = 0;

  String? _world;
  final TextEditingController _worldCustomController = TextEditingController();
  final Set<String> _emotions = {};
  String? _movement;
  final Set<String> _sounds = {};
  String? _vocalCharacter;
  String? _vocalGender;
  final TextEditingController _storyController = TextEditingController();
  String? _chorusStyle;
  String? _lyricsMode;
  final TextEditingController _ownLyricsController = TextEditingController();
  final TextEditingController _creativeDirectionController =
      TextEditingController();

  bool _loadingSpec = false;
  String? _specError;
  MusicSpec? _spec;

  @override
  void dispose() {
    _worldCustomController.dispose();
    _storyController.dispose();
    _ownLyricsController.dispose();
    _creativeDirectionController.dispose();
    super.dispose();
  }

  bool get _needsOwnLyricsField =>
      _lyricsMode == _lyricsOwnFull || _lyricsMode == _lyricsOwnChorus;

  bool get _canGoNext {
    switch (_step) {
      case 0:
        return true;
      case 1:
        return _world != null &&
            (_world != _worldCustomOption ||
                _worldCustomController.text.trim().isNotEmpty);
      case 2:
        return _emotions.isNotEmpty;
      case 3:
        return _movement != null;
      case 4:
        return _sounds.isNotEmpty;
      case 5:
        return _vocalCharacter != null && _vocalGender != null;
      case 6:
        return _storyController.text.trim().isNotEmpty;
      case 7:
        return _chorusStyle != null;
      case 8:
        return _lyricsMode != null &&
            (!_needsOwnLyricsField ||
                _ownLyricsController.text.trim().isNotEmpty);
      default:
        return true;
    }
  }

  void _next() {
    if (!_canGoNext) return;
    setState(() => _step += 1);
    if (_step == 9) _requestSpec();
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step -= 1);
  }

  Map<String, dynamic> _buildAnswers() {
    return {
      'world': _world == _worldCustomOption
          ? _worldCustomController.text.trim()
          : _world,
      'emotion': _emotions.toList(),
      'movement': _movement,
      'sound': _sounds.toList(),
      'vocal_character': _vocalCharacter,
      'vocal_gender': _vocalGender,
      'story': _storyController.text.trim(),
      'chorus': _chorusStyle,
      'lyrics_mode': _lyricsMode,
      if (_needsOwnLyricsField)
        'own_lyrics': _ownLyricsController.text.trim(),
      if (_creativeDirectionController.text.trim().isNotEmpty)
        'creative_direction': _creativeDirectionController.text.trim(),
    };
  }

  Future<void> _requestSpec() async {
    setState(() {
      _loadingSpec = true;
      _specError = null;
    });
    try {
      final spec = await widget.musicSpecService.interpret(
        answers: _buildAnswers(),
        language: 'tr',
      );
      if (!mounted) return;
      setState(() {
        _spec = spec;
        _loadingSpec = false;
      });
    } on MusicSpecException catch (e) {
      if (!mounted) return;
      setState(() {
        _specError = e.message;
        _loadingSpec = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _specError = 'Beklenmeyen bir hata oluştu: $e';
        _loadingSpec = false;
      });
    }
  }

  void _startGeneration() {
    final spec = _spec;
    if (spec == null) return;

    String vocalLabel;
    switch (spec.vocalGender) {
      case 'male':
        vocalLabel = 'Male';
      case 'female':
        vocalLabel = 'Female';
      case 'instrumental':
        vocalLabel = 'Instrumental';
      default: // duet — mevcut Generating akışı 3 seçenek destekliyor
        vocalLabel = 'Female';
    }

    Navigator.of(context)
        .push<dynamic>(
      MaterialPageRoute(
        builder: (_) => GeneratingScreen(
          service: widget.service,
          prompt: spec.lyricalTheme.isNotEmpty
              ? spec.lyricalTheme
              : _storyController.text.trim(),
          genre: spec.genre,
          mood: spec.mood.join(', '),
          vocal: vocalLabel,
          durationSeconds: 120,
          styleOverride: spec.generationPrompt,
          titleOverride: spec.title,
          providedLyrics:
              _needsOwnLyricsField ? _ownLyricsController.text.trim() : null,
        ),
      ),
    )
        .then((song) {
      if (song == null) return;
      widget.library.add(
        LibrarySong(
          song: song,
          genre: spec.genre,
          mood: spec.mood.isNotEmpty ? spec.mood.first : '',
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildProgressDashes(),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _buildStepCard(),
                ),
              ),
              _buildFooterButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          const Text(
            'AI Müzik',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 13),
                SizedBox(width: 4),
                Text(
                  'Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDashes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final filled = index <= _step;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: filled ? AppColors.pink : AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppColors.glassCard(),
      child: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildIntro();
      case 1:
        return _buildSingleChoiceStep(
          title: 'Bu şarkının dünyası nerede?',
          subtitle: 'Sahneyi hayal et — teknik detay yok, sadece atmosfer.',
          options: _worldOptions,
          selected: _world,
          onSelected: (v) => setState(() => _world = v),
          extra: _world == _worldCustomOption
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _buildTextField(
                    controller: _worldCustomController,
                    hint: 'Kendi dünyanı bir iki cümleyle anlat...',
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                  ),
                )
              : null,
        );
      case 2:
        return _buildMultiChoiceStep(
          title: 'Dinleyen ne hissetsin?',
          subtitle: 'Birden fazla seçebilirsin.',
          options: _emotionOptions,
          selected: _emotions,
          onToggle: (v) => setState(
            () => _emotions.contains(v) ? _emotions.remove(v) : _emotions.add(v),
          ),
        );
      case 3:
        return _buildSingleChoiceStep(
          title: 'Şarkı nasıl hareket etsin?',
          subtitle: 'Enerjinin zaman içindeki akışını seç.',
          options: _movementOptions,
          selected: _movement,
          onSelected: (v) => setState(() => _movement = v),
        );
      case 4:
        return _buildMultiChoiceStep(
          title: 'Ses dünyasında hangileri olsun?',
          subtitle: 'Birden fazla seçebilirsin.',
          options: _soundOptions,
          selected: _sounds,
          onToggle: (v) => setState(
            () => _sounds.contains(v) ? _sounds.remove(v) : _sounds.add(v),
          ),
        );
      case 5:
        return _buildVocalStep();
      case 6:
        return _buildStoryStep();
      case 7:
        return _buildSingleChoiceStep(
          title: 'Nakarat nasıl olsun?',
          subtitle: null,
          options: _chorusOptions,
          selected: _chorusStyle,
          onSelected: (v) => setState(() => _chorusStyle = v),
        );
      case 8:
        return _buildLyricsControlStep();
      default:
        return _buildSummaryStep();
    }
  }

  Widget _buildIntro() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Birlikte bir şarkı yapalım',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Birkaç yaratıcı soru soracağız — müzik teorisi hakkında '
          'hiçbir şey bilmene gerek yok. Sadece şarkıyı hayal et.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _buildSingleChoiceStep({
    required String title,
    required String? subtitle,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
    Widget? extra,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(title, subtitle),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = option == selected;
            return GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (extra != null) extra,
      ],
    );
  }

  Widget _buildMultiChoiceStep({
    required String title,
    required String? subtitle,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(title, subtitle),
        const SizedBox(height: 18),
        ChipMultiGroup(options: options, selected: selected, onToggle: onToggle),
      ],
    );
  }

  Widget _buildVocalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Vokal karakteri nasıl?', null),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _vocalCharacterOptions.map((option) {
            final isSelected = option == _vocalCharacter;
            return GestureDetector(
              onTap: () => setState(() => _vocalCharacter = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        const Text(
          'SES',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _vocalGenderOptions.map((option) {
            final isSelected = option == _vocalGender;
            return GestureDetector(
              onTap: () => setState(() => _vocalGender = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Şarkının hikayesi ne?',
          'Aklından geçeni serbestçe yaz, biz gerisini hallederiz.',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _storyController,
          hint:
              'Örn: Para babası bir gangster, geceleri şehirde geziyor, '
              'herkes ona saygı duyuyor ama yalnız.',
          maxLines: 5,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildLyricsControlStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Sözleri ne kadar kontrol etmek istiyorsun?', null),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _lyricsModeOptions.map((option) {
            final isSelected = option == _lyricsMode;
            return GestureDetector(
              onTap: () => setState(() => _lyricsMode = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_needsOwnLyricsField) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _ownLyricsController,
            hint: _lyricsMode == _lyricsOwnChorus
                ? 'Nakaratını buraya yaz...'
                : 'Şarkı sözlerini buraya yaz...',
            maxLines: 6,
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 22),
        const Text(
          'SON DOKUNUŞ (opsiyonel)',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _creativeDirectionController,
          hint:
              'Örn: Modern olsun ama fazla steril olmasın. Bass güçlü '
              'gelsin. Nakaratta patlasın.',
          maxLines: 3,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildSummaryStep() {
    if (_loadingSpec) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.pink),
            SizedBox(height: 18),
            Text(
              'Cevapların profesyonel bir prodüksiyona dönüştürülüyor...',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_specError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.pink, size: 32),
          const SizedBox(height: 12),
          Text(
            _specError!,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Tekrar dene',
            icon: Icons.refresh_rounded,
            onPressed: _requestSpec,
          ),
        ],
      );
    }

    final spec = _spec;
    if (spec == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Senin Şarkın',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...spec.summaryLines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.add_rounded, color: AppColors.pink, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        GradientButton(
          label: 'Şarkıyı Oluştur',
          icon: Icons.auto_awesome_rounded,
          onPressed: _startGeneration,
        ),
      ],
    );
  }

  Widget _stepTitle(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildFooterButtons() {
    // Özet ekranında sonuç geldiyse alt butonlara gerek yok (CTA kart içinde).
    final hideFooter = _step == 9 && !_loadingSpec && _specError == null && _spec != null;
    if (hideFooter) return const SizedBox(height: 12);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _back,
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
              label: Text(
                _step == 0 ? 'Vazgeç' : 'Geri',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          if (_step != 9) ...[
            const SizedBox(width: 10),
            Expanded(
              child: GradientButton(
                label: _step == 0 ? 'Başla' : 'İleri',
                icon: Icons.chevron_right_rounded,
                onPressed: _canGoNext ? _next : null,
                height: 44,
              ),
            ),
          ],
        ],
      ),
    );
  }
}