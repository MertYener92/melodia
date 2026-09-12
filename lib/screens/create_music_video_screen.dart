import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/song.dart';
import '../models/video_package.dart';
import '../services/music_video_service.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'video_generation_screen.dart';

const List<String> _clipStyles = [
  'Cinematic',
  'Emotional',
  'Romantic',
  'Dark',
  'Night',
  'Neon',
  'Performance',
  'Concert',
  'Luxury',
  'Street',
  'Travel',
  'Dramatic',
];

/// "Klibimi Oluştur" akışının ilk ekranı: 3 karakter fotoğrafı + klip
/// tarzı + opsiyonel serbest konsept. Mevcut şarkı üretim akışına hiç
/// dokunmadan, ayrı bir izole modül olarak çalışır (Faz 1).
class CreateMusicVideoScreen extends StatefulWidget {
  const CreateMusicVideoScreen({
    super.key,
    required this.videoService,
    required this.service,
    required this.song,
    required this.genre,
    required this.mood,
    required this.packageType,
  });

  final MusicVideoService videoService;
  final SunoApiService service;
  final Song song;
  final String genre;
  final String mood;

  /// SelectVideoPackageScreen'de seçilen paket — storyboard'un sahne
  /// sayısını ve karakter oranını belirliyor (bkz. backend'deki
  /// videoPackages.js).
  final VideoPackageType packageType;

  @override
  State<CreateMusicVideoScreen> createState() => _CreateMusicVideoScreenState();
}

class _CreateMusicVideoScreenState extends State<CreateMusicVideoScreen> {
  final Map<String, Uint8List> _photos = {}; // front/left/right -> bytes
  String? _style = _clipStyles.first;
  final TextEditingController _conceptController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _conceptController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _photos.length == 3 && !_loading;

  Future<void> _pickPhoto(String slot) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photos[slot] = bytes);
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final frontKey = await widget.videoService.uploadPhoto(
        slot: 'front',
        bytes: _photos['front']!,
        contentType: 'image/jpeg',
      );
      final leftKey = await widget.videoService.uploadPhoto(
        slot: 'left',
        bytes: _photos['left']!,
        contentType: 'image/jpeg',
      );
      final rightKey = await widget.videoService.uploadPhoto(
        slot: 'right',
        bytes: _photos['right']!,
        contentType: 'image/jpeg',
      );

      // DÜZELTME: Kütüphaneden (kaydedilmiş bir şarkıdan) gelindiğinde
      // widget.song.audioUrl BİLİNÇLİ olarak boş bırakılıyor (bkz.
      // song_library.dart — backend artık kalıcı audioUrl döndürmüyor,
      // her zaman taze bir CloudFront linki gerekiyor). Bu ekran daha
      // önce bunu hesaba katmıyor, boş URL'i doğrudan backend'e
      // gönderiyordu — "songAudioUrl zorunludur" hatasının sebebi buydu.
      // Şimdi boşsa /songs/{id}/play-url ile taze bir link alıyoruz.
      final songAudioUrl = widget.song.audioUrl.isNotEmpty
          ? widget.song.audioUrl
          : await widget.service.getSongPlayUrl(widget.song.id);

      final project = await widget.videoService.createProject(
        songId: widget.song.id,
        songTitle: widget.song.title,
        songAudioUrl: songAudioUrl,
        songDurationSeconds: widget.song.duration ?? 60,
        genre: widget.genre,
        mood: widget.mood,
        prompt: widget.song.prompt,
        style: _style ?? 'Cinematic',
        concept: _conceptController.text.trim(),
        photoKeys: {'front': frontKey, 'left': leftKey, 'right': rightKey},
        packageType: widget.packageType == VideoPackageType.premium ? 'premium' : 'economy',
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoGenerationScreen(
            videoService: widget.videoService,
            initialProject: project,
          ),
        ),
      );
    } on MusicVideoException catch (e) {
      setState(() => _error = e.message);
    } on SunoApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Klibimi Oluştur')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Karakterini Oluştur',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Yapay zekanın seni klip boyunca tutarlı şekilde '
                  'oluşturabilmesi için 3 fotoğraf yükle.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PhotoSlot(label: 'Önden', bytes: _photos['front'], onTap: () => _pickPhoto('front')),
                    _PhotoSlot(label: 'Sağ Profil', bytes: _photos['right'], onTap: () => _pickPhoto('right')),
                    _PhotoSlot(label: 'Sol Profil', bytes: _photos['left'], onTap: () => _pickPhoto('left')),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Klip Tarzı',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _clipStyles.map((s) {
                    final isSelected = s == _style;
                    return GestureDetector(
                      onTap: () => setState(() => _style = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.primaryGradient : null,
                          color: isSelected ? null : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Colors.transparent : AppColors.border),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Konsept (opsiyonel)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _conceptController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Örn: Gece yağmur altında yalnız yürüyen bir '
                          'adam, neon şehir ışıkları, duygusal ve sinematik.',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.pink, fontSize: 13)),
                ],
                const SizedBox(height: 28),
                GradientButton(
                  label: _loading ? 'Yükleniyor...' : 'Klip Planı Oluştur',
                  icon: Icons.movie_creation_rounded,
                  isLoading: _loading,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.label, required this.bytes, required this.onTap});

  final String label;
  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              image: bytes != null
                  ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover)
                  : null,
            ),
            child: bytes == null
                ? const Icon(Icons.add_a_photo_rounded, color: AppColors.textMuted, size: 26)
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
      ],
    );
  }
}