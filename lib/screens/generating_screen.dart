import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';

class GeneratingScreen extends StatefulWidget {
  const GeneratingScreen({
    super.key,
    required this.service,
    required this.prompt,
    required this.genre,
    required this.mood,
    required this.vocal,
    required this.durationSeconds,
    this.styleOverride,
    this.titleOverride,
    this.providedLyrics,
  });

  final SunoApiService service;
  final String prompt;
  final String genre;
  final String mood;
  final String vocal; // 'Female' | 'Male' | 'Instrumental'
  final int durationSeconds;

  /// AI Müzik sihirbazından (Gelişmiş mod) gelen zengin stil/başlık/söz
  /// verilmişse bunlar kullanılır; verilmezse davranış eskisiyle aynıdır.
  final String? styleOverride;
  final String? titleOverride;
  final String? providedLyrics;

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

enum _Stage { lyrics, melody, vocals, mastering }

class _GeneratingScreenState extends State<GeneratingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  _Stage _stage = _Stage.lyrics;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _startGeneration();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    final instrumental = widget.vocal == 'Instrumental';
    String? vocalGender;
    if (widget.vocal == 'Female') vocalGender = 'f';
    if (widget.vocal == 'Male') vocalGender = 'm';

    try {
      final song = await widget.service.generateAndWait(
        widget.prompt,
        genre: widget.genre,
        mood: widget.mood,
        vocalGender: vocalGender,
        instrumental: instrumental,
        durationSeconds: widget.durationSeconds,
        styleOverride: widget.styleOverride,
        titleOverride: widget.titleOverride,
        providedLyrics: widget.providedLyrics,
        onLyricsStart: () {
          if (!mounted) return;
          setState(() => _stage = _Stage.lyrics);
        },
        onTick: (status, attempt) {
          if (!mounted) return;
          setState(() => _stage = _stageFor(status, attempt));
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(song);
    } on SunoApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Beklenmeyen bir hata oluştu: $e');
    }
  }

  _Stage _stageFor(TaskStatus status, int attempt) {
    switch (status) {
      case TaskStatus.pending:
        return _Stage.lyrics;
      case TaskStatus.textSuccess:
        return _Stage.melody;
      case TaskStatus.firstSuccess:
        return _Stage.vocals;
      case TaskStatus.success:
        return _Stage.mastering;
      default:
        return _stage;
    }
  }

  double get _progress {
    switch (_stage) {
      case _Stage.lyrics:
        return 0.2;
      case _Stage.melody:
        return 0.5;
      case _Stage.vocals:
        return 0.8;
      case _Stage.mastering:
        return 0.98;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _error != null ? _buildError() : _buildGenerating(),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerating() {
    return Column(
      children: [
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final glow = 0.3 + (_pulseController.value * 0.4);
            return Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.purple, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pink.withValues(alpha: glow),
                    blurRadius: 50,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 3,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.pink,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        const Text(
          'Creating your song...',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        _stageRow('Writing lyrics', _Stage.lyrics),
        const SizedBox(height: 14),
        _stageRow('Composing melody', _Stage.melody),
        const SizedBox(height: 14),
        _stageRow('Generating vocals', _Stage.vocals),
        const SizedBox(height: 14),
        _stageRow('Mixing & mastering', _Stage.mastering),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stageRow(String label, _Stage stage) {
    final isDone = stage.index < _stage.index;
    final isActive = stage == _stage;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isDone || isActive ? AppColors.primaryGradient : null,
            color: isDone || isActive ? null : AppColors.surfaceElevated,
            border: Border.all(
              color: isDone || isActive
                  ? Colors.transparent
                  : AppColors.border,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : isActive
                  ? const Padding(
                      padding: EdgeInsets.all(5),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : null,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDone || isActive
                ? AppColors.textPrimary
                : AppColors.textMuted,
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: AppColors.pink, size: 48),
        const SizedBox(height: 16),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Go back'),
        ),
      ],
    );
  }
}