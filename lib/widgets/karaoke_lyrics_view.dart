import 'package:flutter/material.dart';
import '../models/aligned_word.dart';
import '../theme/app_theme.dart';

/// Şarkı sözlerini, o an söylenen kelimeyi beyaz/parlak renkle
/// vurgulayarak (karaoke tarzı) gösteren widget. [position] her
/// güncellendiğinde otomatik olarak yeniden çizilir ve aktif satıra
/// kayar.
class KaraokeLyricsView extends StatefulWidget {
  const KaraokeLyricsView({
    super.key,
    required this.words,
    required this.position,
  });

  final List<AlignedWord> words;
  final Duration position;

  @override
  State<KaraokeLyricsView> createState() => _KaraokeLyricsViewState();
}

class _KaraokeLyricsViewState extends State<KaraokeLyricsView> {
  final ScrollController _scrollController = ScrollController();
  late List<List<AlignedWord>> _lines;
  int _lastScrolledLine = -1;

  static const double _estimatedLineHeight = 46;

  @override
  void initState() {
    super.initState();
    _lines = _buildLines(widget.words);
  }

  @override
  void didUpdateWidget(covariant KaraokeLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.words, widget.words)) {
      _lines = _buildLines(widget.words);
      _lastScrolledLine = -1;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Suno bazen kelimenin içine "[Verse]\nKelime" gibi bölüm etiketi ve
  /// satır sonu gömer; burada bunları ayrı satırlara ayırıyoruz.
  List<List<AlignedWord>> _buildLines(List<AlignedWord> words) {
    final lines = <List<AlignedWord>>[];
    var current = <AlignedWord>[];

    for (final w in words) {
      final parts = w.word.split('\n');
      for (var i = 0; i < parts.length; i++) {
        final text = parts[i].trim();
        if (text.isNotEmpty) {
          current.add(
            AlignedWord(
              word: text,
              startS: w.startS,
              endS: w.endS,
              success: w.success,
            ),
          );
        }
        if (i < parts.length - 1 && current.isNotEmpty) {
          lines.add(current);
          current = [];
        }
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  double get _positionSeconds => widget.position.inMilliseconds / 1000.0;

  int _activeLineIndex() {
    for (var i = 0; i < _lines.length; i++) {
      if (_lines[i].any((w) => w.isActiveAt(widget.position))) return i;
    }
    for (var i = _lines.length - 1; i >= 0; i--) {
      if (_lines[i].isNotEmpty && _lines[i].first.startS <= _positionSeconds) {
        return i;
      }
    }
    return -1;
  }

  void _autoScrollIfNeeded(int activeLine) {
    if (activeLine < 0 || activeLine == _lastScrolledLine) return;
    if (!_scrollController.hasClients) return;

    _lastScrolledLine = activeLine;
    final target = (activeLine * _estimatedLineHeight - 90)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return const Center(
        child: Text(
          'Bu şarkı için sözler bulunamadı.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final activeLine = _activeLineIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollIfNeeded(activeLine);
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: _lines.length,
      itemBuilder: (context, index) {
        final line = _lines[index];
        final isActiveLine = index == activeLine;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 20),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: line.map((w) {
              final active = w.isActiveAt(widget.position);
              final passed = _positionSeconds > w.endS;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : passed
                            ? Colors.white.withValues(alpha: 0.55)
                            : Colors.white.withValues(alpha: 0.28),
                    fontSize: isActiveLine ? 18 : 15,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    height: 1.4,
                  ),
                  child: Text(w.word),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}