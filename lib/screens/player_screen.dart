import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/aligned_word.dart';
import '../services/player_controller.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/karaoke_lyrics_view.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({
    super.key,
    required this.controller,
    required this.service,
  });

  final PlayerController controller;
  final SunoApiService service;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final song = controller.current?.song;
          if (song == null) {
            return const Center(
              child: Text(
                'No song playing',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          final progress = controller.duration.inMilliseconds == 0
              ? 0.0
              : controller.position.inMilliseconds /
                  controller.duration.inMilliseconds;

          return Container(
            decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Now Playing',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _openLyricsSheet(context, song),
                          icon: const Icon(
                            Icons.lyrics_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: song.imageUrl.isNotEmpty
                          ? Image.network(
                              song.imageUrl,
                              width: 280,
                              height: 280,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderArt(),
                            )
                          : _placeholderArt(),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      song.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'AI Generated',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        activeTrackColor: AppColors.pink,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: progress.clamp(0, 1),
                        onChanged: (value) {
                          final target = Duration(
                            milliseconds:
                                (controller.duration.inMilliseconds * value)
                                    .round(),
                          );
                          controller.seek(target);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(controller.position),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(controller.duration),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: controller.togglePlayPause,
                            icon: Icon(
                              controller.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _PlayerActionsRow(
                      song: song,
                      isFavorite: controller.current!.isFavorite,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openLyricsSheet(BuildContext context, dynamic song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LyricsSheet(
        song: song,
        controller: controller,
        service: service,
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 64),
    );
  }
}

/// Favori / İndir / Paylaş / Listeye ekle butonlarını içeren satır.
/// İndir ve Paylaş, ses dosyasını indirip cihazın native paylaşım/kaydetme
/// menüsünü açar (share_plus) — ekstra depolama izni istemeden çalışan,
/// iOS ve Android'de standart olan yöntem.
class _PlayerActionsRow extends StatefulWidget {
  const _PlayerActionsRow({required this.song, required this.isFavorite});

  final dynamic song; // Song
  final bool isFavorite;

  @override
  State<_PlayerActionsRow> createState() => _PlayerActionsRowState();
}

class _PlayerActionsRowState extends State<_PlayerActionsRow> {
  bool _busy = false;

  String get _safeFileName {
    final raw = widget.song.title as String;
    final cleaned = raw.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    return (cleaned.isEmpty ? 'melodia-song' : cleaned).replaceAll(' ', '_');
  }

  /// Ses dosyasını indirip geçici bir klasöre kaydeder, yerel dosya
  /// yolunu döner. İndirme ve paylaşma aynı temel işlemi kullanır.
  Future<File?> _downloadAudioFile() async {
    final audioUrl = widget.song.audioUrl as String;
    if (audioUrl.isEmpty) {
      _showMessage('Bu şarkı için ses dosyası bulunamadı.');
      return null;
    }

    setState(() => _busy = true);
    try {
      final response = await http
          .get(Uri.parse(audioUrl))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        _showMessage('Dosya indirilemedi (${response.statusCode}).');
        return null;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$_safeFileName.mp3');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      _showMessage('İndirme sırasında bir hata oluştu.');
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onDownloadTap() async {
    if (_busy) return;
    final file = await _downloadAudioFile();
    if (file == null || !mounted) return;

    // Flutter'da uygulamalar arası "indirilenler" klasörüne doğrudan
    // yazma izni gerektirmeden en güvenilir yol: native paylaşım
    // sayfasını açmak. Kullanıcı buradan "Dosyalara Kaydet" / "Save to
    // Files" ile cihazına kalıcı olarak kaydedebilir.
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: widget.song.title as String,
      ),
    );
  }

  Future<void> _onShareTap() async {
    if (_busy) return;
    final file = await _downloadAudioFile();
    if (file == null || !mounted) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '${widget.song.title} — Melodia ile AI ile üretildi 🎵',
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionIcon(
          icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: widget.isFavorite ? AppColors.pink : AppColors.textSecondary,
          onTap: () {},
        ),
        _busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.pink,
                ),
              )
            : _ActionIcon(
                icon: Icons.download_outlined,
                color: AppColors.textSecondary,
                onTap: _onDownloadTap,
              ),
        _ActionIcon(
          icon: Icons.share_outlined,
          color: AppColors.textSecondary,
          onTap: _busy ? () {} : _onShareTap,
        ),
        _ActionIcon(
          icon: Icons.playlist_add,
          color: AppColors.textSecondary,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 24),
    );
  }
}

/// Alttan açılan, karaoke sözlerini gösteren panel. Şarkının [taskId]'si
/// yoksa (örn. çok eski bir kayıt) bunu kullanıcıya açıkça belirtir.
class _LyricsSheet extends StatefulWidget {
  const _LyricsSheet({
    required this.song,
    required this.controller,
    required this.service,
  });

  final dynamic song; // Song
  final PlayerController controller;
  final SunoApiService service;

  @override
  State<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<_LyricsSheet> {
  late final Future<List<AlignedWord>> _future = _load();

  Future<List<AlignedWord>> _load() {
    final taskId = widget.song.taskId as String;
    final audioId = widget.song.id as String;
    if (taskId.isEmpty) return Future.value(const []);
    return widget.service.fetchTimestampedLyrics(
      taskId: taskId,
      audioId: audioId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sözler',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<AlignedWord>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.pink),
                      );
                    }

                    final words = snapshot.data ?? const [];
                    if (words.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Bu şarkı için karaoke sözleri henüz mevcut değil.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }

                    // Canlı çalma pozisyonunu takip etmek için controller'ı
                    // dinliyoruz; kelime vurgusu ve otomatik kaydırma bu
                    // sayede anlık güncellenir.
                    return ListenableBuilder(
                      listenable: widget.controller,
                      builder: (context, _) {
                        return KaraokeLyricsView(
                          words: words,
                          position: widget.controller.position,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}