import 'package:flutter/material.dart';
import '../models/music_spec.dart';
import '../services/music_spec_service.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'generating_screen.dart';

/// "Hızlı" modu: kullanıcı tek cümlede fikrini yazar, arka planda aynı
/// Bedrock yorumlama adımından geçer ama hiçbir soru sorulmaz — en az
/// sürtünmeli yol.
class QuickCreateScreen extends StatefulWidget {
  const QuickCreateScreen({
    super.key,
    required this.service,
    required this.musicSpecService,
    required this.library,
  });

  final SunoApiService service;
  final MusicSpecService musicSpecService;
  final SongLibrary library;

  @override
  State<QuickCreateScreen> createState() => _QuickCreateScreenState();
}

class _QuickCreateScreenState extends State<QuickCreateScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final MusicSpec spec = await widget.musicSpecService.interpret(
        answers: {'story': text, 'creative_direction': text},
        language: 'tr',
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

      final song = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GeneratingScreen(
            service: widget.service,
            prompt: spec.lyricalTheme.isNotEmpty ? spec.lyricalTheme : text,
            genre: spec.genre,
            mood: spec.mood.join(', '),
            vocal: vocalLabel,
            durationSeconds: 120,
            styleOverride: spec.generationPrompt,
            titleOverride: spec.title,
          ),
        ),
      );

      if (song != null) {
        widget.library.add(
          LibrarySong(
            song: song,
            genre: spec.genre,
            mood: spec.mood.isNotEmpty ? spec.mood.first : '',
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() => _loading = false);
      }
    } on MusicSpecException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Beklenmeyen bir hata oluştu: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hızlı Oluştur')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.pink, size: 34),
                const SizedBox(height: 14),
                const Text(
                  'Şarkını tek cümlede anlat',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gerisini yapay zeka tamamlasın — tür, tempo, vokal, '
                  'söz teması, hepsi otomatik.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
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
                    decoration: const InputDecoration(
                      hintText:
                          'Örn: Gece arabayla İstanbul\'da dolaşırken '
                          'dinlenecek, havalı ama biraz karanlık bir şarkı',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                      counterStyle: TextStyle(color: AppColors.textMuted),
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
                GradientButton(
                  label: _loading ? 'Hazırlanıyor...' : 'Oluştur',
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