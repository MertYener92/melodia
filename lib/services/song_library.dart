import 'package:flutter/foundation.dart';
import '../models/song.dart';

/// Kullanıcının bu oturumda ürettiği bir şarkıyı, seçtiği
/// genre/mood metadata'sıyla birlikte saklar.
class LibrarySong {
  LibrarySong({
    required this.song,
    required this.genre,
    required this.mood,
    required this.createdAt,
    this.isFavorite = false,
  });

  final Song song;
  final String genre;
  final String mood;
  final DateTime createdAt;
  bool isFavorite;
}

/// Uygulama genelinde üretilen şarkıları tutan basit, hafif
/// state yöneticisi (dış paket eklemeden ChangeNotifier ile).
///
/// NOT: Bu veri sadece uygulama açıkken bellekte tutulur — kalıcı
/// depolama (veritabanı) değildir. Uygulama kapatılıp açıldığında
/// liste sıfırlanır. Kalıcılık için ileride bir yerel veritabanı
/// (örn. sqflite, hive) veya bir backend eklenmesi gerekir.
class SongLibrary extends ChangeNotifier {
  final List<LibrarySong> _songs = [];

  List<LibrarySong> get songs => List.unmodifiable(_songs.reversed);

  LibrarySong? get lastSong => _songs.isEmpty ? null : _songs.last;

  void add(LibrarySong song) {
    _songs.add(song);
    notifyListeners();
  }

  void toggleFavorite(LibrarySong song) {
    song.isFavorite = !song.isFavorite;
    notifyListeners();
  }

  void remove(LibrarySong song) {
    _songs.remove(song);
    notifyListeners();
  }

  void rename(LibrarySong target, String newTitle) {
    final index = _songs.indexOf(target);
    if (index == -1) return;
    _songs[index] = LibrarySong(
      song: Song(
        id: target.song.id,
        title: newTitle,
        prompt: target.song.prompt,
        audioUrl: target.song.audioUrl,
        streamAudioUrl: target.song.streamAudioUrl,
        imageUrl: target.song.imageUrl,
        duration: target.song.duration,
      ),
      genre: target.genre,
      mood: target.mood,
      createdAt: target.createdAt,
      isFavorite: target.isFavorite,
    );
    notifyListeners();
  }
}