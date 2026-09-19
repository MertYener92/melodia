import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/aligned_word.dart';
import '../models/song.dart';

/// Şarkı açıklaması / söz alanlarının en fazla karakter sayısı (tüm modlar).
/// 200 karakteri aşan açıklamalarda sözleri backend yazar (bkz. lyrics.js).
const int kSongPromptMaxLength = 3000;

/// Kendi AWS backend'imize (Lambda + API Gateway) bağlanan servis.
///
/// ÖNEMLİ: Bu servis artık Suno API'ye doğrudan bağlanmıyor.
/// Suno API key'i telefon uygulamasında hiç bulunmuyor — sadece
/// AWS Secrets Manager'da, sunucu tarafında duruyor. Bu sayede:
///   1) Key hiçbir zaman tersine mühendislikle çalınamaz
///   2) Her kullanıcının aylık kotası backend'de takip edilir
///   3) Kota dolunca istek Suno'ya hiç gitmez, kredi harcanmaz
///
/// Her istek, kullanıcının Cognito girişinden aldığı idToken'ı
/// `Authorization: Bearer <idToken>` başlığıyla gönderir.
class SunoApiService {
  SunoApiService({
    required this.baseUrl,
    required this.idTokenProvider,
    this.onUnauthorized,
    this.model = 'V5_5',
  });

  /// Backend'in ApiUrl'i, örn:
  /// https://xxxxxxxx.execute-api.eu-north-1.amazonaws.com/prod
  final String baseUrl;

  /// Her istekte güncel Cognito idToken'ını döndüren fonksiyon.
  final String? Function() idTokenProvider;

  /// YENİ (401 düzeltmesi): Cognito idToken'ı ~1 saat sonra süresi
  /// doluyordu ve HİÇBİR YERDE tazelenmiyordu -- uygulama açılışından bir
  /// saat sonra backend'e giden her istek API Gateway'de 401 ile
  /// reddediliyor, istek Lambda'ya hiç ulaşmıyordu. Bu callback 401
  /// alındığında oturumu tazeler; true dönerse istek BİR KEZ yeniden
  /// denenir (bkz. [_send]).
  final Future<bool> Function()? onUnauthorized;

  final String model;

  Map<String, String> get _headers {
    final token = idTokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// İsteği gönderir; 401 dönerse [onUnauthorized] ile oturumu tazeleyip
  /// BİR KEZ yeniden dener. [_headers] her çağrıda token'ı yeniden
  /// okuduğu için ikinci deneme otomatik olarak taze token'ı kullanır.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final response = await request();
    if (response.statusCode != 401 || onUnauthorized == null) return response;
    final refreshed = await onUnauthorized!();
    if (!refreshed) return response;
    return request();
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return _send(
      () => http
          .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
          .timeout(
            const Duration(seconds: 35),
            onTimeout: () => throw SunoApiException(
              'Sunucuya bağlanılamadı (zaman aşımı). '
              'İnternet bağlantınızı kontrol edip tekrar deneyin.',
            ),
          ),
    );
  }

  Future<http.Response> _get(String path, Map<String, String> query) {
    return _send(
      () => http
          .get(
            Uri.parse('$baseUrl$path').replace(queryParameters: query),
            headers: _headers,
          )
          .timeout(
            const Duration(seconds: 35),
            onTimeout: () => throw SunoApiException(
              'Sunucuya bağlanılamadı (zaman aşımı). '
              'İnternet bağlantınızı kontrol edip tekrar deneyin.',
            ),
          ),
    );
  }

  // ---------------------------------------------------------------------
  // 1) SÖZ ÜRETİMİ (yalnızca sözlü/instrumental olmayan şarkılar için)
  // ---------------------------------------------------------------------

  Future<String> _requestLyrics(String prompt) async {
    // DEĞİŞTİ: açıklama artık 200 karakterde KESİLMİYOR -- Suno'nun söz ucu
    // en fazla 200 karakter kabul ettiği için daha uzun açıklamalarda
    // backend sözleri kendisi yazıyor (bkz. melodia-backend lyrics.js).
    final trimmedPrompt = prompt.length > kSongPromptMaxLength
        ? prompt.substring(0, kSongPromptMaxLength)
        : prompt;

    final response = await _post('/lyrics', {'prompt': trimmedPrompt});
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw SunoApiException(
        body['error']?.toString() ?? 'Söz üretimi başlatılamadı.',
      );
    }
    final taskId = body['taskId']?.toString();
    if (taskId == null) {
      throw SunoApiException('Sunucudan taskId alınamadı.');
    }
    return taskId;
  }

  Future<({String title, String text})> _checkLyricsStatus(
    String taskId,
  ) async {
    final response = await _get('/lyrics-status', {'taskId': taskId});
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw SunoApiException(
        data['error']?.toString() ?? 'Söz durumu sorgulanamadı.',
      );
    }

    final status = data['status']?.toString();

    if (status == 'SUCCESS') {
      final list = (data['response']
              as Map<String, dynamic>?)?['data'] as List<dynamic>? ??
          [];
      if (list.isEmpty) {
        throw SunoApiException('Söz üretilemedi (boş sonuç).');
      }
      final first = list.first as Map<String, dynamic>;
      return (
        title: first['title']?.toString() ?? '',
        text: first['text']?.toString() ?? '',
      );
    }

    if (status == 'CREATE_TASK_FAILED' ||
        status == 'GENERATE_LYRICS_FAILED' ||
        status == 'CALLBACK_EXCEPTION' ||
        status == 'SENSITIVE_WORD_ERROR') {
      throw SunoApiException(
        data['errorMessage']?.toString() ?? 'Söz üretimi başarısız oldu.',
      );
    }

    throw _StillPending();
  }

  Future<({String title, String text})> _generateLyricsAndWait(
    String prompt,
  ) async {
    final taskId = await _requestLyrics(prompt);
    final deadline = DateTime.now().add(const Duration(minutes: 2));

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        return await _checkLyricsStatus(taskId);
      } on _StillPending {
        continue;
      }
    }
    throw SunoApiException('Zaman aşımı: söz üretimi çok uzun sürdü.');
  }

  // ---------------------------------------------------------------------
  // 2) MÜZİK ÜRETİMİ — kota burada kontrol edilir
  // ---------------------------------------------------------------------

  /// DEĞİŞTİ: /generate artık senkron değil — Suno'ya iletilmeden önce
  /// hemen "202 Accepted" + jobId dönüyor. Gerçek Suno taskId'si daha
  /// sonra /status?jobId=... ile öğrenilir (bkz. checkStatus).
  Future<String> _requestMusic({
    required String lyricsOrEmpty,
    required String style,
    required String title,
    required bool instrumental,
    String? vocalGender,
    int? durationSeconds,
    required String provider,
    String? lyricsLanguage,
    // YENİ (ÇİFT JETON DÜŞME HATASININ DÜZELTMESİ): SongLibrary bu ID'yi
    // AĞ İSTEĞİNDEN ÖNCE diske (flutter_secure_storage) yazıyor. Backend
    // bunu jobId olarak kullanıp koşullu yazıyor -- aynı requestId ile
    // ikinci bir çağrı (uygulama kapanıp açılsa, istek tekrarlansa bile)
    // YENİ bir iş açmıyor/YENİ bir jeton düşmüyor, var olan işi döndürüyor.
    required String requestId,
    // YENİ (JETON SİSTEMİ x10 GÜNCELLEMESİ) — bkz. generateAndWait.
    String? mode,
  }) async {
    final response = await _post('/generate', {
      'instrumental': instrumental,
      if (!instrumental) 'lyrics': lyricsOrEmpty,
      'style': style,
      'title': title,
      'vocalGender': ?vocalGender,
      'durationSeconds': ?durationSeconds,
      // YENİ: hangi motor kullanılacak ('suno' | 'lyria'). Backend
      // verilmezse zaten 'suno' varsayıyor, ama açıkça göndermek daha
      // net -- geriye dönük uyumluluk endişesi yok, bu istemci zaten
      // güncel backend'e konuşuyor.
      'provider': provider,
      // YENİ: Lyria'nın sözleri doğru dilde yazması için -- Suno bu
      // alanı kullanmıyor (kendi söz üretim adımı zaten doğru dilde
      // çalışıyor), sadece Lyria worker'ı okuyor.
      'lyricsLanguage': ?lyricsLanguage,
      'requestId': requestId,
      // YENİ (JETON SİSTEMİ x10 GÜNCELLEMESİ): backend bu değere göre
      // 10 ya da 20 jeton rezerve ediyor -- bkz. creditPlans.js
      // (songCreditCostForMode).
      'mode': ?mode,
    });

    return _jobIdFromGenerateResponse(response);
  }

  /// YENİ (Remix): mevcut bir şarkıyı Suno "upload-cover" ile yeni bir
  /// tarzda yeniden üretir. Kaynak ses dosyasını backend kendisi bulur
  /// (sadece songId gönderiliyor); maliyet backend'de sabit (remix = 10).
  /// Sonuç normal üretimle aynı şekilde (aynı /status akışıyla) döner.
  Future<List<Song>> remixAndWait({
    required String sourceSongId,
    required String style,
    required bool instrumental,
    required String requestId,
    Duration pollInterval = const Duration(seconds: 5),
    Duration timeout = const Duration(minutes: 8),
    void Function(TaskStatus status, int attempt)? onTick,
  }) async {
    final response = await _post('/generate', {
      'remixOf': sourceSongId,
      'style': style,
      'instrumental': instrumental,
      'requestId': requestId,
      'mode': 'remix',
    });
    final jobId = _jobIdFromGenerateResponse(response);
    return _pollUntilDone(
      jobId,
      provider: 'suno',
      pollInterval: pollInterval,
      timeout: timeout,
      onTick: onTick,
    );
  }

  String _jobIdFromGenerateResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 429) {
      throw SunoApiException(
        body['message']?.toString() ??
            'Bu ayki şarkı hakkınızı kullandınız.',
      );
    }
    // 202 = "kabul edildi, kuyruğa alındı" — artık BAŞARI durumu.
    if (response.statusCode != 200 && response.statusCode != 202) {
      throw SunoApiException(
        body['message']?.toString() ?? body['error']?.toString() ?? 'Bilinmeyen hata',
      );
    }

    final jobId = body['jobId']?.toString();
    if (jobId == null) {
      throw SunoApiException('Sunucudan jobId alınamadı.');
    }
    return jobId;
  }

  /// DEĞİŞTİ: artık jobId ile pollanıyor (Suno'nun taskId'si henüz yok
  /// olabilir). Backend, job kuyrukta beklerken {"status":"queued"},
  /// kalıcı olarak başarısız olduysa {"status":"failed","message":...}
  /// döner; iş Suno'ya iletildiyse Suno'nun kendi durum objesini + gerçek
  /// taskId'yi birlikte döner.
  Future<GenerationTask> checkStatus(String jobId) async {
    final response = await _get('/status', {'jobId': jobId});
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw SunoApiException(data['error']?.toString() ?? 'Bilinmeyen hata');
    }

    final metaStatus = data['status']?.toString();
    if (metaStatus == 'queued') {
      return GenerationTask.queued();
    }
    if (metaStatus == 'failed') {
      throw SunoApiException(
        data['message']?.toString() ?? 'Şarkı üretimi başlatılamadı.',
      );
    }

    // job "ready" -> Suno'nun kendi durum objesi + gerçek taskId
    return GenerationTask.fromJson({'data': data});
  }

  /// "Hesabımı Sil" — backend'de kullanıcının TÜM verisini (şarkılar,
  /// video klipleri, kota kaydı) ve Cognito hesabının kendisini siler.
  /// Bu çağrı başarılı olduktan sonra kullanıcı bir daha giriş yapamaz;
  /// çağıran taraf hemen ardından yerel oturumu (secure storage) da
  /// temizlemelidir.
  Future<void> deleteAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/account'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw SunoApiException('Hesap silinemedi. Lütfen tekrar deneyin.');
    }
  }

  /// Uygulama açılışında "kalan hakkınız: X/Y" göstermek için.
  ///
  /// YENİ (Complete Your Profile akışı): backend artık /quota yanıtına
  /// profil alanlarını da (displayName, avatarUrl, favoriteGenres,
  /// moodPreference, creationGoal, profileStep, profileCompleted) ekliyor
  /// -- ayrı bir /profile GET endpoint'i açmaya gerek kalmadı, zaten her
  /// ekran açılışında çağrılan tek bir istekle birlikte geliyor.
  Future<({
    int used,
    int limit,
    int remaining,
    String plan,
    int bonusCredits,
    String? createdAt,
    String? planExpiresAt,
    String? displayName,
    String? avatarUrl,
    List<String> favoriteGenres,
    String? moodPreference,
    String? creationGoal,
    int profileStep,
    bool profileCompleted,
  })> getQuota() async {
    final response = await _get('/quota', {});
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw SunoApiException(body['message']?.toString() ?? 'Kota bilgisi alınamadı.');
    }
    return (
      used: (body['used'] as num?)?.toInt() ?? 0,
      limit: (body['limit'] as num?)?.toInt() ?? 0,
      remaining: (body['remaining'] as num?)?.toInt() ?? 0,
      plan: body['plan']?.toString() ?? 'free',
      // YENİ (kredi paketleri): süresi dolmayan, satın alınmış ekstra
      // bakiye -- periyodik havuzdan (remaining) AYRI.
      bonusCredits: (body['bonusCredits'] as num?)?.toInt() ?? 0,
      // YENİ (profil ekranı): bu değişiklikten önce oluşturulmuş
      // hesaplarda null olabilir -- Flutter tarafı bu durumu ele almalı.
      createdAt: body['createdAt']?.toString(),
      planExpiresAt: body['planExpiresAt']?.toString(),
      displayName: body['displayName']?.toString(),
      avatarUrl: body['avatarUrl']?.toString(),
      favoriteGenres: (body['favoriteGenres'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      moodPreference: body['moodPreference']?.toString(),
      creationGoal: body['creationGoal']?.toString(),
      profileStep: (body['profileStep'] as num?)?.toInt() ?? 0,
      profileCompleted: body['profileCompleted'] == true,
    );
  }

  /// YENİ (Complete Your Profile akışı): profilin bir bölümünü kısmi
  /// olarak günceller. Her adım (isim/avatar/tür/mood) kendi alanını tek
  /// başına gönderir -- kullanıcı akışın ortasında çıksa bile önceki
  /// adımlarda kaydedilen veri kalıcı olarak durur (bkz. updateProfile.js).
  Future<void> updateProfile({
    String? displayName,
    String? avatarKey,
    List<String>? favoriteGenres,
    String? moodPreference,
    String? creationGoal,
    int? profileStep,
  }) async {
    final response = await _post('/profile', {
      'displayName': ?displayName,
      'avatarKey': ?avatarKey,
      'favoriteGenres': ?favoriteGenres,
      'moodPreference': ?moodPreference,
      'creationGoal': ?creationGoal,
      'profileStep': ?profileStep,
    });
    if (response.statusCode != 200) {
      // Genel bir metin yerine sunucunun gerçek hatasını yüzeye çıkar --
      // 401/403/500 ayrımı olmadan sorunu teşhis etmek imkansızdı.
      String detail = 'HTTP ${response.statusCode}';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final error = body['error'] ?? body['message'];
        if (error != null) detail = error.toString();
      } catch (_) {
        // Gövde JSON değilse (ör. API Gateway'in düz 401'i) kod yeterli.
      }
      throw SunoApiException('Profil kaydedilemedi ($detail).');
    }
  }

  /// YENİ (avatar yükleme): backend'den S3'e doğrudan yükleme için
  /// kısa ömürlü bir presigned URL ister, döner: (uploadUrl, key).
  /// `key`, yükleme bittikten sonra [updateProfile]'a `avatarKey` olarak
  /// gönderilmelidir.
  Future<({String uploadUrl, String key})> getAvatarUploadUrl() async {
    final response = await _post('/profile/avatar-upload-url', {});
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw SunoApiException('Yükleme linki alınamadı.');
    }
    return (
      uploadUrl: body['uploadUrl'] as String,
      key: body['key'] as String,
    );
  }

  /// YENİ (avatar yükleme): seçilen fotoğrafı, [getAvatarUploadUrl]'dan
  /// alınan presigned URL'e DOĞRUDAN (backend'e uğramadan) S3 PUT ile
  /// yükler.
  Future<void> uploadAvatarBytes(String uploadUrl, List<int> bytes) async {
    final response = await http
        .put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': 'image/jpeg'},
          body: bytes,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw SunoApiException('Fotoğraf yüklenemedi (zaman aşımı).'),
        );
    if (response.statusCode != 200) {
      throw SunoApiException('Fotoğraf yüklenemedi.');
    }
  }

  /// Apple'dan alınan imzalı satın alma makbuzunu (StoreKit 2'nin
  /// serverVerificationData'sı) backend'e (verifySubscription.js)
  /// göndererek doğrulatır. Başarılı olursa kullanıcının planı ve yeni
  /// bitiş tarihi döner.
  Future<({String plan, String planExpiresAt})> verifySubscription(
    String signedTransactionInfo,
  ) async {
    final response = await _post('/subscription/verify', {
      'signedTransactionInfo': signedTransactionInfo,
    });
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw SunoApiException(
        body['message']?.toString() ?? body['error']?.toString() ?? 'Abonelik doğrulanamadı.',
      );
    }
    return (
      plan: body['plan']?.toString() ?? 'free',
      planExpiresAt: body['planExpiresAt']?.toString() ?? '',
    );
  }

  /// YENİ (JETON SİSTEMİ x10 GÜNCELLEMESİ — kredi paketleri): tüketilebilir
  /// bir kredi paketi satın alındığında Apple'ın imzaladığı makbuzu
  /// backend'e (verifyCreditPurchase.js) gönderip bonusCredits bakiyesine
  /// eklenmesini sağlar. verifySubscription ile AYNI güvenlik deseni.
  Future<int> verifyCreditPurchase(String signedTransactionInfo) async {
    final response = await _post('/credits/verify-purchase', {
      'signedTransactionInfo': signedTransactionInfo,
    });
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw SunoApiException(
        body['message']?.toString() ?? body['error']?.toString() ?? 'Kredi paketi doğrulanamadı.',
      );
    }
    return (body['bonusCredits'] as num?)?.toInt() ?? 0;
  }

  /// Üretilen bir şarkıyı kullanıcının kalıcı kütüphanesine kaydeder
  /// (backend'deki DynamoDB'ye). Kota harcamaz.
  ///
  /// NOT: Backend artık gönderdiğimiz "audioUrl"i (Suno'nun geçici
  /// linki) kaydetmiyor -- kayıt anında kendi S3 bucket'ına indirip
  /// kopyalıyor ve DB'ye sadece bir S3 key yazıyor. Buradan
  /// "audioUrl"i göndermemiz hâlâ gerekli (backend'in indirebilmesi
  /// için kaynak URL), ama artık kalıcı olarak saklanmıyor.
  /// YENİ (kütüphane favori kalıcılığı): saveSongToLibrary'i (tam
  /// PutCommand, ses dosyasını S3'e yeniden kopylar) TEKRAR çağırmak
  /// yerine, sadece isFavorite alanını güncelleyen hafif bir PATCH.
  Future<void> setFavorite(String songId, bool isFavorite) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/songs/$songId'),
          headers: _headers,
          body: jsonEncode({'isFavorite': isFavorite}),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw SunoApiException('Sunucuya bağlanılamadı (zaman aşımı).'),
        );
    if (response.statusCode != 200) {
      throw SunoApiException('Favori durumu güncellenemedi.');
    }
  }

  Future<void> saveSongToLibrary({
    required Song song,
    required String genre,
    required String mood,
    required DateTime createdAt,
    bool isFavorite = false,
    // YENİ (kütüphane sekmesi hatası düzeltmesi): önceden hiç
    // gönderilmiyordu -- şarkı hangi modda (Hızlı/Standart/Gelişmiş)
    // üretildiyse kaydedilmiyordu, bu yüzden uygulama yeniden
    // başlatıldığında şarkılar sadece "Tümü" sekmesinde görünüyordu.
    String? mode,
  }) async {
    final response = await _post('/songs', {
      'songId': song.id,
      'title': song.title,
      'prompt': song.prompt,
      'audioUrl': song.audioUrl,
      'streamAudioUrl': song.streamAudioUrl,
      'imageUrl': song.imageUrl,
      'duration': song.duration,
      'genre': genre,
      'mood': mood,
      'isFavorite': isFavorite,
      'taskId': song.taskId,
      'provider': song.provider,
      'createdAt': createdAt.toIso8601String(),
      'mode': ?mode,
    });

    if (response.statusCode != 200) {
      // Kütüphaneye kaydetme başarısız olsa bile kullanıcı şarkısını
      // zaten aldı; bu hatayı sessizce logluyoruz, üretim akışını bozmuyoruz.
      // ignore: avoid_print
      print('Şarkı kütüphaneye kaydedilemedi: ${response.body}');
    }
  }

  /// Kullanıcının kalıcı kütüphanesindeki tüm şarkıları getirir
  /// (uygulama açılışında My Songs'u doldurmak için).
  Future<List<Map<String, dynamic>>> fetchSavedSongs() async {
    final response = await _get('/songs', {});
    if (response.statusCode != 200) {
      throw SunoApiException('Kütüphane yüklenemedi.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final songs = body['songs'] as List<dynamic>? ?? [];
    return songs.cast<Map<String, dynamic>>();
  }

  /// YENİ: Bir şarkı çalınmak/indirilmek/paylaşılmak istendiğinde
  /// çağrılır. Backend'de DB'ye sabit bir URL yazılmıyor (eski
  /// sistemde bu, birkaç saat içinde ExpiredToken hatasına sebep
  /// oluyordu) -- her çağrıda taze, ~1 saat geçerli bir CloudFront
  /// signed URL üretilip döndürülür. Sonucu önbelleğe alıp saatler
  /// sonra tekrar kullanma.
  Future<String> getSongPlayUrl(String songId) async {
    final response = await _get('/songs/$songId/play-url', {});
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw SunoApiException(body['error']?.toString() ?? 'Şarkı linki alınamadı.');
    }
    return body['playUrl'] as String;
  }

  /// YENİ: Bir şarkının oynatılabilir linki -- oynatma, indirme ve paylaşma
  /// bunu kullanır.
  ///
  /// Yeni üretilen bir şarkı, sunucu ses dosyasını kendi deposuna
  /// kopyalayana kadar (birkaç saniye) kütüphane kaydında yoktur ve
  /// /play-url 404 döner -- kullanıcı bu sırada "Şarkı bulunamadı" görüyordu.
  /// Artık 404'te şarkının üretimden gelen doğrudan adresi (varsa)
  /// kullanılıyor; yoksa kayıt tamamlanana kadar kısa aralıklarla tekrar
  /// deneniyor.
  Future<String> resolvePlayUrl(
    Song song, {
    Duration maxWait = const Duration(seconds: 12),
  }) async {
    final deadline = DateTime.now().add(maxWait);
    var delay = const Duration(milliseconds: 800);
    while (true) {
      final response = await _get('/songs/${song.id}/play-url', {});
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return body['playUrl'] as String;
      if (response.statusCode == 404) {
        if (song.audioUrl.isNotEmpty) return song.audioUrl;
        if (DateTime.now().add(delay).isBefore(deadline)) {
          await Future.delayed(delay);
          delay *= 1.5;
          continue;
        }
      }
      throw SunoApiException(body['error']?.toString() ?? 'Şarkı linki alınamadı.');
    }
  }

  /// YENİ: Kullanıcının kütüphanesinden bir şarkıyı kalıcı olarak siler
  /// (DynamoDB kaydı + varsa S3'teki ses dosyası).
  Future<void> deleteSong(String songId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/songs/$songId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw SunoApiException('Şarkı silinemedi.');
    }
  }

  /// Karaoke gösterimi için kelime bazlı zaman damgalı sözleri getirir.
  /// Enstrümantal şarkılarda veya zamanlama henüz hazır değilse boş
  /// liste döner (hata fırlatmaz — arayüz sessizce "sözler yok" desin).
  Future<List<AlignedWord>> fetchTimestampedLyrics({
    required String taskId,
    required String audioId,
  }) async {
    if (taskId.isEmpty || audioId.isEmpty) return [];

    final response = await _post('/lyrics-timestamps', {
      'taskId': taskId,
      'audioId': audioId,
    });

    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final words = body['alignedWords'] as List<dynamic>? ?? [];
    return words
        .map((e) => AlignedWord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------
  // 3) DIŞARIYA AÇILAN ANA FONKSİYON
  // ---------------------------------------------------------------------

  /// ÖNEMLİ (SunoAPI.org davranışı): Suno için TEK bir /generate isteği
  /// aynı taskId altında HER ZAMAN 2 farklı klip döndürür (V5_5 modeli
  /// varyasyon olarak ikisini birden üretir). Google Lyria ise TEK bir
  /// sonuç döndürür. Bu yüzden bu fonksiyon artık `List<Song>` döndürüyor:
  /// Suno için genelde 2 eleman, Lyria için 1 eleman içerir — hangisi
  /// olduğuna backend'in `sunoData` alanında kaç öğe döndürdüğüne bakarak
  /// karar verilir, provider'a göre AYRI bir dallanma YOKTUR (bu da
  /// Lyria'nın davranışını hiç etkilemez).
  ///
  /// DİKKAT: Bu fonksiyon SADECE TEK bir /generate isteği atar (_requestMusic
  /// bir kez çağrılıyor). İkinci klip için İKİNCİ bir istek ASLA atılmaz —
  /// ikisi de aynı taskId'nin polling sonucundan (task.songs) gelir. Kredi
  /// de zaten backend'de jobId başına (yani bu tek istek başına) bir kez
  /// düşülüyor (bkz. melodia-backend/processMusicGeneration.js deductCredits),
  /// dolayısıyla 2 klip = tek üretim kredisi burada otomatik sağlanıyor.
  Future<List<Song>> generateAndWait(
    String descriptionPrompt, {
    String? genre,
    String? mood,
    String? vocalGender,
    bool instrumental = false,
    int? durationSeconds,
    Duration pollInterval = const Duration(seconds: 5),
    Duration timeout = const Duration(minutes: 8),
    void Function(TaskStatus status, int attempt)? onTick,
    void Function()? onLyricsStart,
    // AI Müzik sihirbazı (Gelişmiş mod) için: Bedrock'un ürettiği zengin
    // stil metnini ve başlığı doğrudan kullanmak, ya da kullanıcının kendi
    // sözlerini/nakaratını AI söz üretimini atlayıp doğrudan kullanmak için.
    // Verilmezse davranış eskisiyle birebir aynı kalır.
    String? styleOverride,
    String? titleOverride,
    String? providedLyrics,
    // YENİ: 'suno' (varsayılan) | 'lyria'. Kullanıcının üretim ekranında
    // seçtiği motor.
    String provider = 'suno',
    // YENİ: Lyria için sözlerin hangi dilde yazılacağı (ör. Bedrock/Claude'un
    // tespit ettiği 'tr'/'en'/'fr' gibi bir dil kodu, ya da Standart modda
    // olduğu gibi uygulamanın o anki arayüz dili). Suno bu alanı kullanmıyor.
    String? lyricsLanguage,
    // YENİ (ÇİFT JETON DÜŞME HATASININ DÜZELTMESİ) — bkz. _requestMusic.
    required String requestId,
    // YENİ (JETON SİSTEMİ x10 GÜNCELLEMESİ): backend artık üretim
    // maliyetini bu değere göre hesaplıyor ('quick' | 'standard' |
    // 'advanced' -- library_mode_filter.dart'taki DEĞERLERLE BİREBİR
    // AYNI olmalı). Verilmezse backend 'standard' maliyetine düşer.
    String? mode,
  }) async {
    final style = (styleOverride != null && styleOverride.isNotEmpty)
        ? styleOverride
        : [
            if (genre != null && genre.isNotEmpty) genre,
            if (mood != null && mood.isNotEmpty) mood,
          ].join(', ');

    String lyrics = '';
    String title = titleOverride ?? _titleFrom(descriptionPrompt);

    if (!instrumental) {
      if (providedLyrics != null && providedLyrics.trim().isNotEmpty) {
        // Kullanıcı kendi sözlerini/nakaratını verdi: AI söz üretimini
        // atla, verdiği metni olduğu gibi kullan.
        lyrics = providedLyrics.trim();
      } else if (provider != 'lyria') {
        // DÜZELTME: Lyria kendi sözlerini TEK istekte kendisi yazıyor
        // (backend'deki buildLyriaPrompt'a bakınız) -- bu yüzden Lyria
        // seçiliyken Suno'ya özel ayrı söz üretim adımını (ki bu hem
        // gereksiz bir Suno çağrısı hem de fazladan gecikme demek)
        // tamamen ATLIYORUZ. lyrics boş kalır, backend Lyria'nın kendi
        // söz yazmasına izin verir.
        onLyricsStart?.call();
        final result = await _generateLyricsAndWait(descriptionPrompt);
        lyrics = result.text;
        if (result.title.isNotEmpty && titleOverride == null) {
          title = result.title;
        }
      }
    }

    // DÜZELTME: Lyria'da açıklama hiç gönderilmiyordu (sözleri Lyria kendisi
    // yazıyor ama neyi anlatacağını bilmiyordu, sadece şarkı adı açıklamanın
    // ilk kelimeleriydi). Açıklama artık Lyria'nın tarif metnine ekleniyor.
    var effectiveStyle = style.isEmpty ? 'Pop' : style;
    final description = descriptionPrompt.trim();
    if (provider == 'lyria' && description.isNotEmpty) {
      effectiveStyle = '$effectiveStyle. Song description: $description';
    }

    final jobId = await _requestMusic(
      lyricsOrEmpty: lyrics,
      style: effectiveStyle,
      title: title,
      instrumental: instrumental,
      vocalGender: vocalGender,
      durationSeconds: durationSeconds,
      provider: provider,
      lyricsLanguage: lyricsLanguage,
      requestId: requestId,
      mode: mode,
    );

    return _pollUntilDone(jobId, provider: provider, pollInterval: pollInterval, timeout: timeout, onTick: onTick);
  }

  /// YENİ (ÇİFT JETON DÜŞME HATASININ DÜZELTMESİ): Uygulama kapanıp
  /// açıldığında, diskte kalmış (daha önce ÖDENMİŞ, backend'de zaten
  /// devam eden) bir job varsa BUNU çağır -- generateAndWait'i BAŞTAN
  /// çağırma. generateAndWait yeni bir /generate isteği (ve dolayısıyla
  /// backend'de requestId eşleşmezse teorik olarak yeni bir jeton
  /// düşümü riski) taşır; resumeGeneration ise SADECE var olan jobId'yi
  /// pollar, hiçbir yeni istek/jeton riski yoktur.
  Future<List<Song>> resumeGeneration(
    String jobId, {
    String provider = 'suno',
    Duration pollInterval = const Duration(seconds: 5),
    Duration timeout = const Duration(minutes: 8),
    void Function(TaskStatus status, int attempt)? onTick,
  }) {
    return _pollUntilDone(jobId, provider: provider, pollInterval: pollInterval, timeout: timeout, onTick: onTick);
  }

  Future<List<Song>> _pollUntilDone(
    String jobId, {
    required String provider,
    required Duration pollInterval,
    required Duration timeout,
    void Function(TaskStatus status, int attempt)? onTick,
  }) async {
    final deadline = DateTime.now().add(timeout);
    int attempt = 0;

    while (DateTime.now().isBefore(deadline)) {
      attempt++;
      await Future.delayed(pollInterval);

      final task = await checkStatus(jobId);

      if (task.isQueued) {
        // Backend işi henüz Suno'ya iletmedi (kuyrukta bekliyor ya da
        // geçici bir Suno hatası nedeniyle otomatik olarak yeniden
        // deneniyor). Kullanıcıya "beklemede" göster, süre dolana kadar
        // pollamaya devam et — sistem kendi kendine düzeliyor olabilir.
        onTick?.call(TaskStatus.pending, attempt);
        continue;
      }

      onTick?.call(task.status, attempt);

      if (task.status.isComplete && task.songs.isNotEmpty) {
        // ÖNEMLİ: jobId DEĞİL, backend'in Suno'dan aldığı GERÇEK taskId
        // kullanılıyor — karaoke/zaman damgalı söz gibi Suno'ya özel
        // isteklerde jobId'nin hiçbir anlamı yok.
        //
        // DÜZELTME: Önceden burada SADECE `task.songs.first` döndürülüp
        // Suno'nun aynı taskId altında ürettiği İKİNCİ klip sessizce
        // ATILIYORDU. Artık backend'in döndürdüğü TÜM klipler (Suno için
        // genelde 2, Lyria için 1) korunuyor -- ikinci bir API isteği
        // ATILMADAN, aynı tek generation'ın tüm çıktıları döndürülüyor.
        final resolvedTaskId = task.taskId ?? jobId;
        return task.songs
            .map((song) => song.copyWith(taskId: resolvedTaskId, provider: provider))
            .toList();
      }
      if (task.status.isFailed) {
        throw SunoApiException(
          task.errorMessage ??
              'Şarkı üretimi başarısız oldu (${task.status}).',
        );
      }
    }

    throw SunoApiException('Zaman aşımı: şarkı üretimi çok uzun sürdü.');
  }

  String _titleFrom(String prompt) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return 'Adsız şarkı';
    final words = trimmed.split(RegExp(r'\s+')).take(6).join(' ');
    return words.length > 80 ? words.substring(0, 80) : words;
  }
}

class _StillPending implements Exception {}

class SunoApiException implements Exception {
  SunoApiException(this.message);
  final String message;

  @override
  String toString() => message;
}