import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'song_library.dart';
import 'suno_api_service.dart';

/// Tekrar modu: kapalı / tüm kuyruk / tek şarkı.
enum PlayerRepeatMode { off, all, one }

/// Mini-player ve tam ekran player arasında paylaşılan, tek bir
/// AudioPlayer örneğini yöneten controller.
class PlayerController extends ChangeNotifier {
  PlayerController({required this.service, this.queueSource}) {
    // YENİ (arka planda çalma): iOS ses oturumunu açıkça "playback"
    // kategorisine alıyoruz -- uygulamadaki video_player'lar (splash,
    // arka plan videoları) oturum kategorisini değiştirebildiği için
    // varsayılana güvenmiyoruz. Info.plist'teki UIBackgroundModes=audio
    // ile birlikte, uygulama arka plana alınınca çalma devam eder.
    if (!kIsWeb) {
      _player
          .setAudioContext(
            AudioContext(
              iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
            ),
          )
          .catchError((Object _) {});
    }
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
    // YENİ: şarkı bitince tekrar/karışık moduna göre sıradakine geç.
    // Tek şarkı tekrarında ReleaseMode.loop zaten başa sarıyor (bu event
    // loop modunda da geldiği için burada hiçbir şey yapmıyoruz).
    _player.onPlayerComplete.listen((_) {
      if (_repeatMode == PlayerRepeatMode.one) return;
      _advance(1, wrap: _repeatMode == PlayerRepeatMode.all);
    });
  }

  /// Şarkı oynatılmak istendiğinde taze bir CloudFront signed URL
  /// almak için kullanılır (bkz. [SunoApiService.getSongPlayUrl]).
  final SunoApiService service;

  /// YENİ: Sonraki/önceki için çalma sırası. HomeShell bunu kütüphanedeki
  /// şarkı listesine bağlıyor; ayrı bir kuyruk kopyası tutulmuyor, böylece
  /// kütüphane değiştikçe sıra da kendiliğinden güncel kalıyor.
  List<LibrarySong> Function()? queueSource;

  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  LibrarySong? _current;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;
  bool _loading = false;
  bool _shuffle = false;
  PlayerRepeatMode _repeatMode = PlayerRepeatMode.off;

  LibrarySong? get current => _current;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasSong => _current != null;
  String? get error => _error;
  bool get isLoading => _loading;
  bool get shuffle => _shuffle;
  PlayerRepeatMode get repeatMode => _repeatMode;

  /// Sonraki/önceki butonlarının etkin olup olmadığı.
  bool get canSkip => _queue.length > 1;

  /// Sadece çalınabilir (üretimi tamamlanmış) şarkılar.
  List<LibrarySong> get _queue {
    final source = queueSource?.call() ?? const <LibrarySong>[];
    return source
        .where((s) => s.pendingId == null && s.song.id.isNotEmpty)
        .toList();
  }

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

  /// YENİ: Kuyruktaki sonraki şarkı (sonda başa sarar).
  Future<void> next() => _advance(1, wrap: true);

  /// YENİ: Şarkının ilk 3 saniyesinden sonra basılırsa başa sarar, aksi
  /// halde önceki şarkıya geçer (müzik uygulamalarındaki standart davranış).
  Future<void> previous() async {
    if (position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    await _advance(-1, wrap: true);
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  /// Kapalı -> tümü -> tek şarkı -> kapalı.
  Future<void> cycleRepeatMode() async {
    _repeatMode = PlayerRepeatMode
        .values[(_repeatMode.index + 1) % PlayerRepeatMode.values.length];
    notifyListeners();
    await _player.setReleaseMode(
      _repeatMode == PlayerRepeatMode.one
          ? ReleaseMode.loop
          : ReleaseMode.release,
    );
  }

  Future<void> _advance(int direction, {required bool wrap}) async {
    final current = this.current;
    final queue = _queue;
    if (current == null || queue.isEmpty) return;

    LibrarySong target;
    if (_shuffle && queue.length > 1) {
      final others = queue.where((s) => s.song.id != current.song.id).toList();
      target = others[_random.nextInt(others.length)];
    } else {
      final index = queue.indexWhere((s) => s.song.id == current.song.id);
      var nextIndex = index == -1
          ? (direction > 0 ? 0 : queue.length - 1)
          : index + direction;
      if (nextIndex < 0 || nextIndex >= queue.length) {
        if (!wrap) return;
        nextIndex = (nextIndex + queue.length) % queue.length;
      }
      target = queue[nextIndex];
    }

    if (target.song.id == current.song.id) {
      // Kuyrukta tek şarkı var: başa sarıp çalmaya devam et.
      await seek(Duration.zero);
      await _player.resume();
      return;
    }
    await playSong(target);
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
