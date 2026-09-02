import 'package:flutter/material.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chip_group.dart';
import '../widgets/gradient_button.dart';
import 'generating_screen.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({
    super.key,
    required this.service,
    required this.library,
  });

  final SunoApiService service;
  final SongLibrary library;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _promptController = TextEditingController();

  static const _genres = ['Pop', 'Rock', 'Hip-Hop', 'EDM', 'R&B', 'Acoustic'];
  static const _moods = ['Happy', 'Chill', 'Energetic', 'Sad', 'Romantic'];
  static const _vocals = ['Female', 'Male', 'Instrumental'];
  static const _lengths = ['Short', 'Medium', 'Long'];

  String _genre = _genres.first;
  String _mood = _moods.first;
  String _vocal = _vocals.first;
  String _length = _lengths[1];

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
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your song first.')),
      );
      return;
    }

    final song = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GeneratingScreen(
          service: widget.service,
          prompt: prompt,
          genre: _genre,
          mood: _mood,
          vocal: _vocal,
          durationSeconds: _lengthToSeconds[_length] ?? 90,
        ),
      ),
    );

    if (song != null) {
      widget.library.add(
        LibrarySong(
          song: song,
          genre: _genre,
          mood: _mood,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your song is ready! 🎶')),
        );
        _promptController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create your next song',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Turn your ideas into music with AI',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 22),
            _buildPromptCard(),
            const SizedBox(height: 22),
            ChipGroup(
              label: 'GENRE',
              options: _genres,
              selected: _genre,
              onSelected: (v) => setState(() => _genre = v),
            ),
            const SizedBox(height: 18),
            ChipGroup(
              label: 'MOOD',
              options: _moods,
              selected: _mood,
              onSelected: (v) => setState(() => _mood = v),
            ),
            const SizedBox(height: 18),
            ChipGroup(
              label: 'VOCAL',
              options: _vocals,
              selected: _vocal,
              onSelected: (v) => setState(() => _vocal = v),
            ),
            const SizedBox(height: 18),
            ChipGroup(
              label: 'SONG LENGTH',
              options: _lengths,
              selected: _length,
              onSelected: (v) => setState(() => _length = v),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Generate Song',
              icon: Icons.auto_awesome,
              onPressed: _generate,
              height: 58,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Describe your song',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _promptController,
            maxLines: 4,
            maxLength: 300,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'A romantic pop song about summer nights...',
              counterStyle: const TextStyle(color: AppColors.textMuted),
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