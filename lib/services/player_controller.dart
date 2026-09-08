import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'song_library.dart';
import 'suno_api_service.dart';

/// Mini-player ve tam ekran player arasında paylaşılan, tek bir
/// AudioPlayer örneğini yöneten controller.
class PlayerController extends ChangeNotifier {
  PlayerController({required this.service}) {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });
    _player.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });
    _player.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });
  }

  /// Şarkı oynatılmak istendiğinde taze bir CloudFront signed URL
  /// almak için kullanılır (bkz. [SunoApiService.getSongPlayUrl]).
  final SunoApiService service;

  final AudioPlayer _player = AudioPlayer();

  LibrarySong? _current;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;
  bool _loading = false;

  LibrarySong? get current => _current;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasSong => _current != null;
  String? get error => _error;
  bool get isLoading => _loading;

  /// DEĞİŞTİ: Artık şarkının kendi üzerindeki (audioUrl/streamAudioUrl)
  /// sabit linki KULLANILMIYOR -- backend artık bu alanları kalıcı
  /// saklamıyor. Her çalma denemesinde [service.getSongPlayUrl] ile
  /// taze bir link isteniyor.
  Future<void> playSong(LibrarySong librarySong) async {
    if (_current?.song.id == librarySong.song.id) {
      await togglePlayPause();
      return;
    }

    _current = librarySong;
    _position = Duration.zero;
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      final url = await service.getSongPlayUrl(librarySong.song.id);
      await _player.play(UrlSource(url));
    } on SunoApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Şarkı oynatılamadı.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> close() async {
    await _player.stop();
    _current = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}