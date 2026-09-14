import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'suno_api_service.dart';

/// Bir üretim kartının hangi aşamada olduğunu gösterir. Sadece
/// [LibrarySong.pendingId] doluyken (yani üretim devam ederken) anlamlı.
enum GenerationPhase { lyrics, melody, vocals, mastering, failed }

/// Kullanıcının bu oturumda ürettiği bir şarkıyı, seçtiği
/// genre/mood metadata'sıyla birlikte saklar.
///
/// YENİ: Artık tamamlanmış bir şarkıyı DEĞİL, devam eden bir üretimi de
/// temsil edebilir. [pendingId] doluysa bu bir "generation card"dır:
/// [song] alanları henüz boş/placeholder'dır, gerçek içerik
/// [phase] ilerledikçe ve en sonunda üretim tamamlandığında güncellenir.
class LibrarySong {
  LibrarySong({
    required this.song,
    required this.genre,
    required this.mood,
    required this.createdAt,
    this.isFavorite = false,
    this.pendingId,
    this.phase,
    this.errorMessage,
  });

  final Song song;
  final String genre;
  final String mood;
  final DateTime createdAt;
  bool isFavorite;

  /// YENİ: Şarkı hâlâ üretiliyorsa benzersiz bir yerel kimlik taşır;
  /// üretim tamamlandığında bu kart tamamen normal bir [LibrarySong] ile
  /// (pendingId=null) DEĞİŞTİRİLİR -- yeni bir kart EKLENMEZ. Aynı
  /// pendingId'ye sahip birden fazla kart asla listede bulunmaz (bkz.
  /// SongLibrary.startGeneration / _updatePendingPhase).
  final String? pendingId;

  /// pendingId doluyken üretimin hangi aşamada olduğu (ya da başarısız
  /// olduysa [GenerationPhase.failed]).
  final GenerationPhase? phase;

  /// Üretim başarısız olduysa kullanıcıya gösterilecek hata mesajı.
  final String? errorMessage;

  bool get isGenerating => pendingId != null && phase != GenerationPhase.failed;
  bool get isFailedGeneration => pendingId != null && phase == GenerationPhase.failed;

  /// Devam eden bir üretim için geçici kart oluşturur.
  factory LibrarySong.pending({
    required String pendingId,
    required String genre,
    required String mood,
  }) {
    return LibrarySong(
      song: Song(
        id: pendingId,
        title: '',
        prompt: '',
        audioUrl: '',
        streamAudioUrl: '',
        imageUrl: '',
      ),
      genre: genre,
      mood: mood,
      createdAt: DateTime.now(),
      pendingId: pendingId,
      phase: GenerationPhase.lyrics,
    );
  }

  LibrarySong copyWithPhase(GenerationPhase newPhase) {
    return LibrarySong(
      song: song,
      genre: genre,
      mood: mood,
      createdAt: createdAt,
      isFavorite: isFavorite,
      pendingId: pendingId,
      phase: newPhase,
    );
  }

  LibrarySong copyWithError(String message) {
    return LibrarySong(
      song: song,
      genre: genre,
      mood: mood,
      createdAt: createdAt,
      isFavorite: isFavorite,
      pendingId: pendingId,
      phase: GenerationPhase.failed,
      errorMessage: message,
    );
  }

  /// Backend'den (`GET /songs`) gelen bir DynamoDB kaydını çözümler.
  /// Kalıcı kütüphaneden yüklenen şarkılar asla "pending" olamaz.
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
/// - YENİ: [startGeneration] çağrıldığında ANINDA bir "generation card"
///   (placeholder) listeye eklenir ve arka planda (SongLibrary,
///   HomeShell'de tek bir singleton olarak tutulduğu için ekran
///   değişse/navigasyon yapılsa bile) polling devam eder. Bu, artık
///   ayrı bir loading sayfası açmadan, Suno tarzı "liste içinde üretim
///   kartı" deneyimini sağlar.
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
      // ÖNEMLİ: Devam eden üretim kartlarını (pendingId != null) burada
      // KAYBETMEMEK gerekir -- loadFromBackend uygulama açılışı dışında
      // (ör. aşağı çekip yenileme) da çağrılabilir; o an ekranda bir
      // generation card varsa backend'den gelen liste onun yerini
      // ALMAMALI, sadece tamamlanmış şarkıları güncellemeli.
      final pending = _songs.where((s) => s.pendingId != null).toList();
      _songs
        ..clear()
        ..addAll(
          rawSongs.map(LibrarySong.fromBackendJson).toList()
            // En eski en başta olacak şekilde sırala (UI zaten .reversed
            // ile en yeniyi üstte gösteriyor).
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        )
        ..addAll(pending);
    } catch (e) {
      _loadError = 'Şarkılarınız yüklenemedi. Çekmek için aşağı çekin.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void add(LibrarySong song) {
    // YENİ: Aynı clipId (song.song.id) zaten kütüphanede varsa tekrar
    // ekleme -- callback/polling/refresh kaynaklı ya da (Suno'nun aynı
    // taskId altında döndürdüğü 2 klipten kaynaklanan) yanlışlıkla
    // tekrar çağrılma ihtimaline karşı duplicate'i burada da engelliyoruz.
    if (song.pendingId == null &&
        _songs.any((s) => s.pendingId == null && s.song.id == song.song.id)) {
      return;
    }
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

  /// YENİ: Şarkı üretimini ANINDA (bekletmeden) başlatır.
  ///
  /// Davranış:
  ///   1) Listeye TEK bir placeholder ("generation card") eklenir ve
  ///      hemen `notifyListeners()` çağrılır -- çağıran taraf bu
  ///      Future'ı beklemeden (await ETMEDEN) hemen Şarkılarım ekranına
  ///      geçebilir, kart zaten orada olur.
  ///   2) Suno/Lyria durumu değiştikçe (onLyricsStart/onTick) AYNI
  ///      kart yerinde güncellenir -- asla ikinci bir kart eklenmez
  ///      (bkz. _updatePendingPhase: pendingId ile arama yapar,
  ///      bulamazsa hiçbir şey yapmaz, YENİ eleman eklemez).
  ///   3) Üretim bittiğinde placeholder, tamamlanmış gerçek şarkı(lar)la
  ///      DEĞİŞTİRİLİR (aynı liste index'inde) ve backend'e kaydedilir.
  ///      Suno tek istekten aynı taskId altında 2 klip döndürdüğü için
  ///      burada 1 ya da 2 kart oluşabilir -- ama bu İKİ AYRI ÜRETİM
  ///      DEĞİLDİR, aynı tek generation'ın çıktılarıdır (bkz. clipId
  ///      bazlı duplicate koruması, her clipId yalnızca bir kez eklenir).
  ///   4) Hata olursa kart "failed" durumuna geçer; kullanıcı isterse
  ///      [removePending] ile kartı kapatabilir.
  ///
  /// SongLibrary, HomeShell tarafından tek bir örnek (singleton) olarak
  /// tutulduğu için kullanıcı üretim sırasında başka bir ekrana geçse
  /// (ya da geri dönse) bile bu Future arka planda çalışmaya devam eder.
  Future<void> startGeneration({
    required String prompt,
    required String displayGenre,
    required String displayMood,
    String? genre,
    String? mood,
    String? vocalGender,
    bool instrumental = false,
    int? durationSeconds,
    String? styleOverride,
    String? titleOverride,
    String? providedLyrics,
    String provider = 'suno',
    String? lyricsLanguage,
  }) async {
    final pendingId =
        'gen_${DateTime.now().microsecondsSinceEpoch}_${_songs.length}';

    // Savunma amaçlı: aynı pendingId zaten listede varsa (pratikte
    // mikrosaniye damgası nedeniyle imkansıza yakın) tekrar eklemek
    // yerine hiçbir şey yapma.
    if (_songs.any((s) => s.pendingId == pendingId)) return;

    _songs.add(
      LibrarySong.pending(
        pendingId: pendingId,
        genre: displayGenre,
        mood: displayMood,
      ),
    );
    notifyListeners();

    try {
      // ÖNEMLİ: Bu TEK bir generateAndWait çağrısı -- yani TEK bir Suno/
      // Lyria API generation isteği. SunoAPI.org, tek bir istek için aynı
      // taskId altında HER ZAMAN 2 klip döndürür; bu yüzden dönüş tipi
      // artık List<Song> (Lyria için genelde 1, Suno için genelde 2
      // eleman). İkinci klip için İKİNCİ bir istek ASLA atılmıyor -- ikisi
      // de burada, aynı `songs` listesinde birlikte gelir. Kredi de
      // backend'de bu tek isteğe karşılık zaten sadece bir kez düşülüyor.
      final songs = await service.generateAndWait(
        prompt,
        genre: genre,
        mood: mood,
        vocalGender: vocalGender,
        instrumental: instrumental,
        durationSeconds: durationSeconds,
        styleOverride: styleOverride,
        titleOverride: titleOverride,
        providedLyrics: providedLyrics,
        provider: provider,
        lyricsLanguage: lyricsLanguage,
        onLyricsStart: () =>
            _updatePendingPhase(pendingId, GenerationPhase.lyrics),
        onTick: (status, attempt) =>
            _updatePendingPhase(pendingId, _phaseFor(status)),
      );

      if (songs.isEmpty) {
        _failPending(pendingId, 'Şarkı üretilemedi (boş sonuç).');
        return;
      }

      final createdAt = DateTime.now();

      // DUPLICATE KORUMASI: Her klip kendi benzersiz clipId'siyle (song.id)
      // tanımlanır. Aynı clipId zaten kütüphanede varsa (ör. bu Future
      // bir şekilde iki kez tetiklendiyse, ya da aşağıdaki kaydetme arka
      // planda tekrarlandıysa) o klip TEKRAR EKLENMEZ -- her clipId
      // kütüphaneye yalnızca bir kez girer.
      final newEntries = <LibrarySong>[
        for (final song in songs)
          if (!_songs.any((s) => s.pendingId == null && s.song.id == song.id))
            LibrarySong(
              song: song,
              genre: displayGenre,
              mood: displayMood,
              createdAt: createdAt,
            ),
      ];

      final index = _songs.indexWhere((s) => s.pendingId == pendingId);
      // Kullanıcı bu arada kartı silmiş olabilir (removePending) --
      // o zaman şarkıları listeye geri EKLEMİYORUZ (kullanıcının "sil"
      // kararına saygı), sadece arka planda kalıcı kütüphaneye kaydediyoruz.
      if (index != -1) {
        if (newEntries.isEmpty) {
          // Bütün klipler zaten kütüphanede (duplicate) -- placeholder'ı
          // olduğu gibi kaldır, yeni bir şey eklemeye gerek yok.
          _songs.removeAt(index);
        } else {
          // İlk klip, placeholder kartın YERİNE geçer (aynı satırda
          // "tamamlanır"). Suno'dan gelen İKİNCİ klip varsa -- bu aynı
          // generation'ın ikinci çıktısı, YENİ bir üretim DEĞİL -- listenin
          // en üstüne (en yeni konuma) eklenir. İkisi de aynı taskId'yi
          // taşıdığı için "iki ayrı üretim" değil, "bir üretimin iki
          // çıktısı" olarak kalıyor; kullanıcıya kredi/UX açısından tek
          // üretim gibi sunuluyor, sadece kütüphanede iki ayrı kart
          // görünüyor.
          _songs[index] = newEntries.first;
          for (final extra in newEntries.skip(1)) {
            _songs.add(extra);
          }
        }
        notifyListeners();
      }

      // Her klip backend'in kalıcı kütüphanesine AYRI AYRI kaydedilir
      // (ikisi de aynı taskId'yi taşır, ama farklı songId/clipId'leri
      // vardır) -- bu sadece metadata persist etmek içindir, kota BURADA
      // TEKRAR HARCANMAZ (kota zaten backend'de tek /generate isteği
      // başına bir kez düşülüyor, bkz. processMusicGeneration.js).
      for (final entry in newEntries) {
        service
            .saveSongToLibrary(
              song: entry.song,
              genre: displayGenre,
              mood: displayMood,
              createdAt: createdAt,
            )
            .catchError((_) {});
      }
    } on SunoApiException catch (e) {
      _failPending(pendingId, e.message);
    } catch (e) {
      _failPending(pendingId, 'Beklenmeyen bir hata oluştu: $e');
    }
  }

  void _updatePendingPhase(String pendingId, GenerationPhase phase) {
    final index = _songs.indexWhere((s) => s.pendingId == pendingId);
    // Kart bulunamadıysa (silinmiş ya da zaten tamamlanmış) hiçbir şey
    // yapma -- YENİ bir kart asla eklenmez, bu yüzden duplicate oluşamaz.
    if (index == -1) return;
    _songs[index] = _songs[index].copyWithPhase(phase);
    notifyListeners();
  }

  void _failPending(String pendingId, String message) {
    final index = _songs.indexWhere((s) => s.pendingId == pendingId);
    if (index == -1) return;
    _songs[index] = _songs[index].copyWithError(message);
    notifyListeners();
  }

  GenerationPhase _phaseFor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return GenerationPhase.lyrics;
      case TaskStatus.textSuccess:
        return GenerationPhase.melody;
      case TaskStatus.firstSuccess:
        return GenerationPhase.vocals;
      case TaskStatus.success:
        return GenerationPhase.mastering;
      default:
        return GenerationPhase.lyrics;
    }
  }

  /// Başarısız (ya da kullanıcının vazgeçtiği) bir üretim kartını
  /// listeden kaldırır. Sadece pendingId dolu kartlar için geçerlidir.
  void removePending(LibrarySong song) {
    if (song.pendingId == null) return;
    _songs.removeWhere((s) => s.pendingId == song.pendingId);
    notifyListeners();
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