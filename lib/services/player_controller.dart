import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'song_library.dart';

/// Mini-player ve tam ekran player arasında paylaşılan, tek bir
/// AudioPlayer örneğini yöneten controller.
class PlayerController extends ChangeNotifier {
  PlayerController() {
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

  final AudioPlayer _player = AudioPlayer();

  LibrarySong? _current;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  LibrarySong? get current => _current;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasSong => _current != null;

  Future<void> playSong(LibrarySong librarySong) async {
    final url = librarySong.song.audioUrl.isNotEmpty
        ? librarySong.song.audioUrl
        : librarySong.song.streamAudioUrl;
    if (url.isEmpty) return;

    if (_current?.song.id != librarySong.song.id) {
      _current = librarySong;
      _position = Duration.zero;
      notifyListeners();
      await _player.play(UrlSource(url));
    } else {
      await togglePlayPause();
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