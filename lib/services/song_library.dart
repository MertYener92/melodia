import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'suno_api_service.dart';

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

  /// Backend'den (`GET /songs`) gelen bir DynamoDB kaydını çözümler.
  factory LibrarySong.fromBackendJson(Map<String, dynamic> json) {
    return LibrarySong(
      song: Song(
        id: json['songId']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Adsız şarkı',
        prompt: json['prompt']?.toString() ?? '',
        // NOT: backend artık "audioUrl" döndürmüyor (kalıcı olarak
        // saklamıyor) -- bu alanlar boş kalır, oynatma/indirme artık
        // SunoApiService.getSongPlayUrl(songId) ile yapılıyor.
        audioUrl: json['audioUrl']?.toString() ?? '',
        streamAudioUrl: json['streamAudioUrl']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString() ?? '',
        duration: (json['duration'] as num?)?.toDouble(),
        taskId: json['taskId']?.toString() ?? '',
      ),
      genre: json['genre']?.toString() ?? '',
      mood: json['mood']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isFavorite: json['isFavorite'] == true,
    );
  }
}

/// Uygulama genelinde üretilen şarkıları tutan, backend'deki (DynamoDB)
/// kalıcı kütüphaneyle senkronize çalışan state yöneticisi.
///
/// - Uygulama açılışında [loadFromBackend] çağrılarak kullanıcının daha
///   önce ürettiği tüm şarkılar geri yüklenir.
/// - [add] çağrıldığında hem yerel listeye eklenir (anlık UI güncellemesi
///   için) hem de arka planda backend'e kaydedilir (kalıcılık için).
class SongLibrary extends ChangeNotifier {
  SongLibrary({required this.service});

  final SunoApiService service;

  final List<LibrarySong> _songs = [];
  bool _loading = false;
  String? _loadError;

  List<LibrarySong> get songs => List.unmodifiable(_songs.reversed);
  LibrarySong? get lastSong => _songs.isEmpty ? null : _songs.last;
  bool get isLoading => _loading;
  String? get loadError => _loadError;

  /// Uygulama açılışında bir kez çağrılır: kullanıcının backend'deki
  /// kalıcı kütüphanesini çeker.
  Future<void> loadFromBackend() async {
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      final rawSongs = await service.fetchSavedSongs();
      _songs
        ..clear()
        ..addAll(
          rawSongs.map(LibrarySong.fromBackendJson).toList()
            // En eski en başta olacak şekilde sırala (UI zaten .reversed
            // ile en yeniyi üstte gösteriyor).
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        );
    } catch (e) {
      _loadError = 'Şarkılarınız yüklenemedi. Çekmek için aşağı çekin.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void add(LibrarySong song) {
    _songs.add(song);
    notifyListeners();

    // Kalıcı kütüphaneye arka planda kaydet; başarısız olsa bile
    // kullanıcı şarkısını zaten dinleyebiliyor, akışı bloklamıyoruz.
    service
        .saveSongToLibrary(
          song: song.song,
          genre: song.genre,
          mood: song.mood,
          createdAt: song.createdAt,
          isFavorite: song.isFavorite,
        )
        .catchError((_) {});
  }

  void toggleFavorite(LibrarySong song) {
    song.isFavorite = !song.isFavorite;
    notifyListeners();
    // NOT: Favori durumu şu an backend'e senkronize edilmiyor
    // (gelecek bir iyileştirme olarak eklenebilir).
  }

  /// DEĞİŞTİ: Önceden sadece yerel listeden çıkarıyordu -- uygulama
  /// kapanıp açıldığında backend'den tekrar çekildiği için şarkı geri
  /// geliyordu. Artık backend'e de gerçek bir silme isteği gönderiyor.
  Future<void> remove(LibrarySong song) async {
    _songs.remove(song);
    notifyListeners();

    try {
      await service.deleteSong(song.song.id);
    } catch (e) {
      // Backend silme başarısız olduysa, şarkıyı listeye geri koy ki
      // kullanıcı hâlâ silindiğini sanıp yanılmasın.
      _songs.add(song);
      notifyListeners();
      rethrow;
    }
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
        taskId: target.song.taskId,
      ),
      genre: target.genre,
      mood: target.mood,
      createdAt: target.createdAt,
      isFavorite: target.isFavorite,
    );
    notifyListeners();
  }
}