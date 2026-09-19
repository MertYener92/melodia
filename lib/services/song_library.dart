import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    this.mode,
  });

  final Song song;
  final String genre;
  final String mood;
  final DateTime createdAt;
  bool isFavorite;

  /// YENİ: Şarkının hangi üretim modunda oluşturulduğu -- 'quick'
  /// (Hızlı), 'standard' (Standart), 'advanced' (Gelişmiş). Kütüphane
  /// ekranlarındaki filtre çipleri (bkz. widgets/library_mode_filter.dart)
  /// bu alana göre süzüyor. `null` = mod bilgisi yok (backend henüz bu
  /// alanı desteklemediği için, sadece YEREL oturumda üretilen şarkılar
  /// bu alanı taşır -- backend'den (loadFromBackend) yüklenen geçmiş
  /// şarkılarda şimdilik null'dur, sadece "Tümü" filtresinde görünürler).
  final String? mode;

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
    String? mode,
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
      mode: mode,
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
      mode: mode,
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
      mode: mode,
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
        provider: json['provider']?.toString() ?? 'suno',
      ),
      genre: json['genre']?.toString() ?? '',
      mood: json['mood']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isFavorite: json['isFavorite'] == true,
      // NOT: backend şu an bu alanı DÖNDÜRMÜYOR (mode, henüz backend'e
      // eklenmedi) -- ileride eklenirse otomatik okunur, o zamana kadar
      // her zaman null gelir (bkz. LibraryFilterMode.matches).
      mode: json['mode']?.toString(),
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

  // YENİ (ÇİFT JETON DÜŞME HATASININ DÜZELTMESİ): auth_service.dart'ın
  // zaten kullandığı flutter_secure_storage burada da kullanılıyor --
  // yeni bir paket eklemeye gerek yok. Burada SADECE "devam eden, zaten
  // ÖDENMİŞ bir üretim var mı" bilgisini tutuyoruz -- şarkının kendisi
  // değil, sadece onu geri BULMAK için gereken minimum bilgi (jobId +
  // ekranı yeniden çizmek için birkaç metadata alanı).
  static const _storage = FlutterSecureStorage();
  static const _pendingGenerationKey = 'melodia_pending_generation_v1';

  final List<LibrarySong> _songs = [];
  bool _loading = false;
  String? _loadError;

  List<LibrarySong> get songs => List.unmodifiable(_songs.reversed);
  LibrarySong? get lastSong => _songs.isEmpty ? null : _songs.last;
  bool get isLoading => _loading;
  String? get loadError => _loadError;

  // DÜZELTME (kredi rozeti bayatlığı): Kota artık her ekranın kendi
  // State'inde AYRI AYRI (ve sadece Navigator.push().then() geri
  // dönüşünde) tutulmuyor. CreateScreen/AiMusicScreen HomeShell'de
  // IndexedStack içinde canlı tutulduğu için initState bir daha hiç
  // çalışmıyordu; üstüne QuickCreateScreen/CreateFormScreen/
  // MusicWizardScreen üretim başladığı ANDA pushAndRemoveUntil ile
  // TÜM ara route'ları (dolayısıyla onların .then(_loadQuota)
  // callback'lerini) kaldırıyordu -- üretim daha bitmeden, o ekranlar
  // zaten yok oluyordu. Sonuç: rozet, üretim tamamlanıp kredi gerçekten
  // düşene kadar hiç yenilenmiyor, ancak uygulama kapatılıp açıldığında
  // (her şey initState'ten yeniden kurulduğunda) güncel değeri
  // gösteriyordu. Artık kota, SongLibrary gibi tek bir singleton'da
  // (HomeShell ömrü boyunca canlı, ChangeNotifier) tutuluyor ve üretim
  // her bitişinde (başarılı ya da başarısız) burada tazeleniyor --
  // ekranlar sadece bu singleton'ı dinliyor, kendi kopyalarını
  // tutmuyorlar.
  int? _remainingCredits;
  String? _quotaError;
  // YENİ (kredi paketleri + "Kredi Al" rozeti): önceden getQuota()'nın
  // döndürdüğü plan/bonusCredits hiç saklanmıyordu -- sadece remaining
  // kullanılıyordu. Artık ikisi de saklanıyor: plan, rozetin "Pro" mu
  // "Kredi Al" mı göstereceğine karar vermek için; bonusCredits,
  // kullanıcının toplam kullanılabilir jetonunu (remaining + bonusCredits)
  // doğru göstermek için.
  String? _plan;
  int _bonusCredits = 0;
  // YENİ (profil ekranı): hesap oluşturulma ve plan yenilenme tarihleri.
  String? _createdAt;
  String? _planExpiresAt;

  // YENİ (Complete Your Profile akışı): /quota ile birlikte gelen profil
  // alanları -- ayrı bir controller AÇMADAN, kota ile aynı yerde (tek
  // singleton, tek refresh) tutuluyor.
  String? _displayNameOverride;
  String? _avatarUrl;
  List<String> _favoriteGenres = const [];
  String? _moodPreference;
  String? _creationGoal;
  int _profileStep = 0;
  bool _profileCompleted = false;

  int? get remainingCredits => _remainingCredits;
  String? get quotaError => _quotaError;
  String? get plan => _plan;
  int get bonusCredits => _bonusCredits;
  bool get isPro => (_plan ?? '').startsWith('pro_');
  String? get memberSince => _createdAt;
  String? get planExpiresAt => _planExpiresAt;

  String? get displayNameOverride => _displayNameOverride;
  String? get avatarUrl => _avatarUrl;
  List<String> get favoriteGenres => _favoriteGenres;
  String? get moodPreference => _moodPreference;
  String? get creationGoal => _creationGoal;
  int get profileStep => _profileStep;
  bool get profileCompleted => _profileCompleted;

  /// YENİ (Complete Your Profile akışı): bir adımı backend'e kaydeder ve
  /// ANINDA yerel state'i de günceller (tam bir refreshQuota() beklemeden
  /// -- akış ekranı her adımda hemen ilerleyebilsin diye). Adım 4'e
  /// ulaşıldığında profileCompleted otomatik true olur (bkz.
  /// updateProfile.js).
  Future<void> updateProfileStep({
    String? displayName,
    String? avatarKey,
    List<String>? favoriteGenres,
    String? moodPreference,
    String? creationGoal,
    required int profileStep,
  }) async {
    await service.updateProfile(
      displayName: displayName,
      avatarKey: avatarKey,
      favoriteGenres: favoriteGenres,
      moodPreference: moodPreference,
      creationGoal: creationGoal,
      profileStep: profileStep,
    );
    if (displayName != null) _displayNameOverride = displayName;
    if (favoriteGenres != null) _favoriteGenres = favoriteGenres;
    if (moodPreference != null) _moodPreference = moodPreference;
    if (creationGoal != null) _creationGoal = creationGoal;
    _profileStep = profileStep;
    if (profileStep >= 4) _profileCompleted = true;
    notifyListeners();
    // Avatar yüklendiyse taze bir signed URL için tam bir kota yenilemesi
    // gerekir (avatarUrl backend'de imzalanıyor) -- diğer alanlar için
    // gerekmez, gereksiz bir ağ isteği atmayalım.
    if (avatarKey != null) {
      await refreshQuota();
    }
  }

  /// Kotayı backend'den tazeler ve dinleyicileri bilgilendirir.
  /// Uygulama açılışında, her üretim bitişinde (başarı/hata fark etmez)
  /// ve satın alma ekranı kapandığında çağrılır -- ekranların kendi
  /// yerel kopyasını tutmasına gerek kalmaz.
  Future<void> refreshQuota() async {
    try {
      final quota = await service.getQuota();
      _remainingCredits = quota.remaining;
      _plan = quota.plan;
      _bonusCredits = quota.bonusCredits;
      _createdAt = quota.createdAt;
      _planExpiresAt = quota.planExpiresAt;
      _displayNameOverride = quota.displayName;
      _avatarUrl = quota.avatarUrl;
      _favoriteGenres = quota.favoriteGenres;
      _moodPreference = quota.moodPreference;
      _creationGoal = quota.creationGoal;
      _profileStep = quota.profileStep;
      _profileCompleted = quota.profileCompleted;
      _quotaError = null;
    } catch (e) {
      _quotaError = e.toString();
    }
    notifyListeners();
  }

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
          mode: song.mode,
        )
        .catchError((_) {});
  }

  /// YENİ: Şarkı üretimini ANINDA (bekletmeden) başlatır.
  ///
  /// Davranış:
  ///   1) Listeye placeholder ("generation card") eklenir ve hemen
  ///      `notifyListeners()` çağrılır -- çağıran taraf bu Future'ı
  ///      beklemeden (await ETMEDEN) hemen Şarkılarım ekranına geçebilir,
  ///      kart(lar) zaten orada olur. Provider 'suno' ise BAŞTAN 2
  ///      placeholder eklenir (SunoAPI.org'un tek istekten her zaman 2
  ///      klip döndürdüğü bilindiği için); Lyria için her zaman 1.
  ///   2) Suno/Lyria durumu değiştikçe (onLyricsStart/onTick) TÜM
  ///      placeholder'lar birlikte güncellenir -- aynı tek job/taskId'nin
  ///      parçası oldukları için ilerlemeleri ortak. Asla YENİ bir kart
  ///      eklenmez (bkz. _updatePendingPhase: pendingId ile arama yapar,
  ///      bulamazsa hiçbir şey yapmaz).
  ///   3) Üretim bittiğinde, SADECE gerçekten dolu (id+audioUrl dolu) ve
  ///      benzersiz (clipId daha önce kütüphanede yoksa) klipler
  ///      placeholder'ların YERİNE geçer. Beklenen ama gelmeyen bir slot
  ///      varsa (ör. Suno bu sefer 2 yerine 1 klip döndürdüyse) o
  ///      placeholder kaldırılır -- boş/kırık kart asla gösterilmez. Bu
  ///      birden fazla kart İKİ AYRI ÜRETİM DEĞİLDİR, aynı tek
  ///      generation'ın çıktılarıdır.
  ///   4) Hata olursa TÜM kart(lar) "failed" durumuna geçer; kullanıcı
  ///      isterse [removePending] ile kapatabilir.
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
    // YENİ: kütüphane filtre çipleri (Hızlı/Standart/Gelişmiş) için --
    // çağıran ekran (QuickCreateScreen/CreateFormScreen/MusicWizardScreen)
    // kendi modunu geçirir.
    String? mode,
  }) async {
    final baseId = 'gen_${DateTime.now().microsecondsSinceEpoch}_${_songs.length}';

    // YENİ: SADECE Suno için baştan 2 generation card gösteriyoruz --
    // SunoAPI.org'un tek istekten aynı taskId altında 2 klip döndürdüğü
    // bilindiği için (bkz. suno_api_service.dart), kullanıcı Suno'nun
    // kendi uygulamasındaki gibi ikisinin de birlikte hazırlandığını
    // görebiliyor. Lyria'nın davranışı DEĞİŞMEDİ -- her zaman tek kart.
    final expectedCount = provider == 'suno' ? 2 : 1;
    final pendingIds = _addPendingPlaceholders(
      baseId,
      expectedCount,
      displayGenre,
      displayMood,
      mode: mode,
    );

    // DÜZELTME (ÇİFT JETON DÜŞME HATASI): requestId = baseId, AĞ
    // İSTEĞİNDEN ÖNCE diske yazılıyor. Uygulama üretim bitmeden kapanıp
    // açılırsa, HomeShell açılışta resumePendingGenerationIfAny()'yi
    // çağırıp bu kaydı bulur ve YENİ bir /generate isteği (dolayısıyla
    // YENİ bir jeton düşümü) ATMADAN sadece var olan işin sonucunu
    // bekler -- kullanıcının "üretim kayboldu sanıp tekrar basması" (ve
    // bunun ikinci kez ücretlendirilmesi) ihtimali ortadan kalkar.
    final requestId = baseId;
    await _writePendingGeneration({
      'requestId': requestId,
      'provider': provider,
      'baseId': baseId,
      'expectedCount': expectedCount,
      'displayGenre': displayGenre,
      'displayMood': displayMood,
      'mode': mode,
    });

    await _finishGeneration(
      pendingIds: pendingIds,
      displayGenre: displayGenre,
      displayMood: displayMood,
      mode: mode,
      run: () => service.generateAndWait(
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
        requestId: requestId,
        mode: mode,
        onLyricsStart: () => _updateAllPhases(pendingIds, GenerationPhase.lyrics),
        onTick: (status, attempt) => _updateAllPhases(pendingIds, _phaseFor(status)),
      ),
    );
  }

  /// YENİ (Remix): [source] şarkısını [style] tarzında yeniden üretir
  /// (Suno upload-cover). Normal üretimle AYNI akışı kullanır: kütüphanede
  /// 2 "üretiliyor" kartı belirir, uygulama kapanırsa açılışta kaldığı
  /// yerden devam edilir, başarısızlıkta jeton backend'de iade edilir.
  ///
  /// [styleLabel] kartlarda/şarkıda görünen kısa etiket (ör. "Akustik"),
  /// [style] Suno'ya giden asıl tarif. Tamamlanınca eklenen şarkıları döner.
  Future<List<LibrarySong>> startRemix({
    required LibrarySong source,
    required String style,
    required String styleLabel,
    bool instrumental = false,
  }) async {
    const mode = 'remix';
    const displayMood = 'Remix';
    final baseId = 'remix_${DateTime.now().microsecondsSinceEpoch}_${_songs.length}';
    const expectedCount = 2; // remix her zaman Suno -- 2 klip döner
    final pendingIds = _addPendingPlaceholders(
      baseId,
      expectedCount,
      styleLabel,
      displayMood,
      mode: mode,
    );

    // startGeneration ile aynı: requestId ağ isteğinden ÖNCE diske yazılır,
    // backend bunu jobId olarak kullanır -- tekrar istek yeni jeton düşmez.
    final requestId = baseId;
    await _writePendingGeneration({
      'requestId': requestId,
      'provider': 'suno',
      'baseId': baseId,
      'expectedCount': expectedCount,
      'displayGenre': styleLabel,
      'displayMood': displayMood,
      'mode': mode,
    });

    return _finishGeneration(
      pendingIds: pendingIds,
      displayGenre: styleLabel,
      displayMood: displayMood,
      mode: mode,
      run: () => service.remixAndWait(
        sourceSongId: source.song.id,
        style: style,
        instrumental: instrumental,
        requestId: requestId,
        onTick: (status, attempt) => _updateAllPhases(pendingIds, _phaseFor(status)),
      ),
    );
  }

  /// YENİ (ÇİFT JETON DÜŞME HATASININ DÜZELTMESİ): HomeShell tarafından
  /// uygulama açılışında BİR KEZ çağrılır. Diskte yarım kalmış (daha önce
  /// ÖDENMİŞ, backend'de hâlâ devam ediyor ya da zaten bitmiş olabilecek)
  /// bir üretim varsa, YENİ bir istek/jeton harcamadan sadece onun
  /// sonucunu bekleyip kullanıcıya gösterir. Kayıt yoksa hiçbir şey
  /// yapmaz (no-op) -- normal açılışta ekstra bir maliyeti yoktur.
  Future<void> resumePendingGenerationIfAny() async {
    final pending = await _readPendingGeneration();
    if (pending == null) return;

    final requestId = pending['requestId']?.toString();
    final baseId = pending['baseId']?.toString();
    if (requestId == null || baseId == null) {
      await _clearPendingGeneration();
      return;
    }

    final provider = pending['provider']?.toString() ?? 'suno';
    final expectedCount = (pending['expectedCount'] as num?)?.toInt() ?? 1;
    final displayGenre = pending['displayGenre']?.toString() ?? '';
    final displayMood = pending['displayMood']?.toString() ?? '';
    final mode = pending['mode']?.toString();

    final pendingIds = _addPendingPlaceholders(
      baseId,
      expectedCount,
      displayGenre,
      displayMood,
      mode: mode,
    );

    await _finishGeneration(
      pendingIds: pendingIds,
      displayGenre: displayGenre,
      displayMood: displayMood,
      mode: mode,
      run: () => service.resumeGeneration(
        requestId,
        provider: provider,
        onTick: (status, attempt) => _updateAllPhases(pendingIds, _phaseFor(status)),
      ),
    );
  }

  /// pendingIds'e karşılık gelen placeholder ("generation card") kartları
  /// listeye ekler -- zaten varsa (ör. resume sırasında hot-restart)
  /// tekrar EKLEMEZ, idempotenttir. Her zaman TAM pendingIds listesini
  /// döndürür (yeni eklensin ya da eklenmesin), çağıran taraf pollama/
  /// sonuç-işleme için bunu kullanır.
  List<String> _addPendingPlaceholders(
    String baseId,
    int expectedCount,
    String displayGenre,
    String displayMood, {
    String? mode,
  }) {
    final pendingIds = [for (var i = 0; i < expectedCount; i++) '${baseId}_$i'];
    for (final id in pendingIds) {
      if (_songs.any((s) => s.pendingId == id)) continue;
      _songs.add(
        LibrarySong.pending(pendingId: id, genre: displayGenre, mood: displayMood, mode: mode),
      );
    }
    notifyListeners();
    return pendingIds;
  }

  void _updateAllPhases(List<String> pendingIds, GenerationPhase phase) {
    for (final id in pendingIds) {
      _updatePendingPhase(id, phase);
    }
  }

  /// [startGeneration] ve [resumePendingGenerationIfAny] tarafından
  /// paylaşılan ortak sonuç-işleme mantığı -- tek fark, üretimin NASIL
  /// başlatıldığı ([run] closure'ı: ya YENİ bir /generate isteği, ya da
  /// var olan bir job'un sadece pollanması).
  ///
  /// Başarılı olursa kütüphaneye eklenen şarkıları, aksi halde boş liste döner.
  Future<List<LibrarySong>> _finishGeneration({
    required List<String> pendingIds,
    required String displayGenre,
    required String displayMood,
    required Future<List<Song>> Function() run,
    String? mode,
  }) async {
    try {
      // ÖNEMLİ: Bu TEK bir üretim isteğine karşılık gelir -- yani TEK bir
      // Suno/Lyria API generation isteği. SunoAPI.org, tek bir istek için
      // aynı taskId altında HER ZAMAN 2 klip döndürür; bu yüzden dönüş
      // tipi List<Song> (Lyria için genelde 1, Suno için genelde 2
      // eleman). İkinci klip için İKİNCİ bir istek ASLA atılmıyor -- ikisi
      // de burada, aynı `songs` listesinde birlikte gelir. Kredi de
      // backend'de bu tek isteğe karşılık zaten sadece bir kez düşülüyor.
      final songs = await run();

      // DOLULUK KONTROLÜ: Sadece gerçekten kullanılabilir (id VE audioUrl
      // dolu) klipler "gelmiş" sayılır. Suno bu sefer beklenmedik şekilde
      // sadece 1 (ya da hiç) dolu klip döndürürse, karşılığı olmayan
      // placeholder(lar) aşağıda sessizce kaldırılır -- boş/kırık bir kart
      // asla gösterilmez.
      final populatedSongs = songs
          .where((s) => s.id.isNotEmpty && s.audioUrl.isNotEmpty)
          .toList();

      if (populatedSongs.isEmpty) {
        for (final id in pendingIds) {
          _failPending(id, 'Şarkı üretilemedi (boş sonuç).');
        }
        await _clearPendingGeneration();
        return const [];
      }

      final createdAt = DateTime.now();
      final created = <LibrarySong>[];

      // DUPLICATE KORUMASI: Her klip kendi benzersiz clipId'siyle (song.id)
      // tanımlanır. Aynı clipId zaten kütüphanede varsa (ör. bu Future
      // bir şekilde iki kez tetiklendiyse, ya da aşağıdaki kaydetme arka
      // planda tekrarlandıysa) o klip TEKRAR EKLENMEZ -- her clipId
      // kütüphaneye yalnızca bir kez girer.
      final uniqueSongs = <Song>[
        for (final song in populatedSongs)
          if (!_songs.any((s) => s.pendingId == null && s.song.id == song.id))
            song,
      ];

      // Kullanıcı bu arada bazı kartları silmiş olabilir (removePending)
      // -- o zaman o slotu listeye geri EKLEMİYORUZ (kullanıcının "sil"
      // kararına saygı), sadece arka planda kalıcı kütüphaneye kaydediyoruz.
      for (var i = 0; i < pendingIds.length; i++) {
        final index = _songs.indexWhere((s) => s.pendingId == pendingIds[i]);
        if (index == -1) continue;
        if (i < uniqueSongs.length) {
          // Bu placeholder, dolu ve benzersiz bir klip ile tamamlanıyor.
          _songs[index] = LibrarySong(
            song: uniqueSongs[i],
            genre: displayGenre,
            mood: displayMood,
            createdAt: createdAt,
            mode: mode,
          );
          created.add(_songs[index]);
        } else {
          // Bu slot için karşılığı olan (dolu/benzersiz) bir klip GELMEDİ
          // -- ör. Suno bu sefer sadece 1 klip döndürdü, ya da ikinci klip
          // duplicate çıktı. Kullanılmayan placeholder kaldırılır, boş
          // kart asla gösterilmez.
          _songs.removeAt(index);
        }
      }
      // Beklenenden FAZLA benzersiz/dolu klip geldiyse (savunma amaçlı,
      // normalde olmaz) kalanlar listenin en üstüne yeni kart olarak
      // eklenir.
      for (var i = pendingIds.length; i < uniqueSongs.length; i++) {
        final extra = LibrarySong(
          song: uniqueSongs[i],
          genre: displayGenre,
          mood: displayMood,
          createdAt: createdAt,
          mode: mode,
        );
        _songs.add(extra);
        created.add(extra);
      }
      notifyListeners();

      // Her klip backend'in kalıcı kütüphanesine AYRI AYRI kaydedilir
      // (ikisi de aynı taskId'yi taşır, ama farklı songId/clipId'leri
      // vardır) -- bu sadece metadata persist etmek içindir, kota BURADA
      // TEKRAR HARCANMAZ (kota zaten backend'de tek /generate isteği
      // başına bir kez düşülüyor, bkz. processMusicGeneration.js).
      for (final song in uniqueSongs) {
        service
            .saveSongToLibrary(
              song: song,
              genre: displayGenre,
              mood: displayMood,
              createdAt: createdAt,
              mode: mode,
            )
            .catchError((_) {});
      }

      // Üretim (başarıyla) bitti -- diskteki "devam ediyor" kaydını
      // temizle, aksi halde bir sonraki açılışta boş yere resume denenir.
      await _clearPendingGeneration();
      return created;
    } on SunoApiException catch (e) {
      for (final id in pendingIds) {
        _failPending(id, e.message);
      }
      await _clearPendingGeneration();
      return const [];
    } catch (e) {
      for (final id in pendingIds) {
        _failPending(id, 'Beklenmeyen bir hata oluştu: $e');
      }
      await _clearPendingGeneration();
      return const [];
    } finally {
      // DÜZELTME (kredi rozeti bayatlığı): üretim ister başarıyla ister
      // hatayla bitsin, ekranlardaki rozetin (ve varsa Pro/kota bağlı
      // diğer göstergelerin) hemen güncellenmesi için kota burada,
      // TEK yerden tazelenir -- ekranların Navigator pop'una bağlı ayrı
      // ayrı yenileme mantığına artık gerek yok.
      await refreshQuota();
    }
  }

  Future<void> _writePendingGeneration(Map<String, dynamic> data) async {
    try {
      await _storage.write(key: _pendingGenerationKey, value: jsonEncode(data));
    } catch (_) {
      // Diske yazamazsak bile üretimi ENGELLEMİYORUZ -- sadece resume
      // garantisi kaybolur, bu kritik değil (eski davranışa geriler).
    }
  }

  Future<Map<String, dynamic>?> _readPendingGeneration() async {
    try {
      final raw = await _storage.read(key: _pendingGenerationKey);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearPendingGeneration() async {
    try {
      await _storage.delete(key: _pendingGenerationKey);
    } catch (_) {
      // Silinemezse bir sonraki açılışta gereksiz bir resume denemesi
      // olur -- zararsız (backend zaten "ready"/"failed" döner, iş
      // tekrar ücretlendirilmez), bu yüzden burada sessizce yutuyoruz.
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

  /// DÜZELTME: önceden SADECE bellekte tutuluyordu (uygulama kapanınca
  /// kayboluyordu) -- artık backend'e de kalıcı olarak yazılıyor.
  /// remove() ile AYNI iyimser (optimistic) desen: önce yerel durumu
  /// değiştir + bildir, arka planda backend'e gönder, başarısız olursa
  /// eski duruma geri al.
  Future<void> toggleFavorite(LibrarySong song) async {
    final previous = song.isFavorite;
    song.isFavorite = !previous;
    notifyListeners();
    try {
      await service.setFavorite(song.song.id, song.isFavorite);
    } catch (_) {
      song.isFavorite = previous;
      notifyListeners();
    }
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
        provider: target.song.provider,
      ),
      genre: target.genre,
      mood: target.mood,
      createdAt: target.createdAt,
      isFavorite: target.isFavorite,
    );
    notifyListeners();
  }
}