import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

/// sunoapi.org REST API'sine bağlanan servis.
///
/// Resmi dokümantasyon: https://docs.sunoapi.org
/// API key almak için: https://sunoapi.org/api-key
///
/// NOT: sunoapi.org, Suno Inc.'in resmi bir servisi değildir —
/// bağımsız üçüncü bir taraftır (kredi bazlı ücretlendirir).
///
/// ÖNEMLİ TASARIM NOTU:
/// Süre (duration) kontrolü API'de sadece customMode:true VE
/// model:V5_5 iken çalışıyor. Ama customMode:true olduğunda,
/// gönderdiğiniz "prompt" alanı otomatik söz üretmek yerine
/// DOĞRUDAN şarkı sözü olarak kullanılıyor. Kullanıcının yazdığı
/// "babasını kaybeden biri için hüzünlü şarkı" gibi bir AÇIKLAMAYI
/// gerçek şarkı sözlerine çevirmek için, önce ayrı bir "lyrics"
/// (söz üretme) isteği atıyoruz, sonra o sözlerle asıl şarkı
/// üretim isteğini gönderiyoruz. Bu yüzden sözlü şarkılar iki
/// API çağrısı (ve muhtemelen 2 kredi) gerektiriyor.
class SunoApiService {
  SunoApiService({
    required this.apiKey,
    this.baseUrl = 'https://api.sunoapi.org',
    this.model = 'V5_5',
  });

  /// API key'inizi doğrudan koda yazmayın; --dart-define ile verin:
  /// flutter run --dart-define=SUNO_API_KEY=xxxx
  final String apiKey;
  final String baseUrl;

  /// Süre (duration) kontrolü SADECE V5_5 modelinde çalışıyor,
  /// bu yüzden varsayılan model V5_5.
  final String model;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

  // ---------------------------------------------------------------------
  // 1) SÖZ ÜRETİMİ (yalnızca sözlü/instrumental olmayan şarkılar için)
  // ---------------------------------------------------------------------

  Future<String> _requestLyrics(
    String prompt, {
    String callBackUrl = 'https://example.com/callback',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/lyrics');
    final trimmedPrompt =
        prompt.length > 200 ? prompt.substring(0, 200) : prompt;

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'prompt': trimmedPrompt,
        'callBackUrl': callBackUrl,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['code'] != 200) {
      throw SunoApiException(
        _errorMessageFor(body['code']) ??
            body['msg']?.toString() ??
            'Söz üretimi başlatılamadı.',
      );
    }

    final taskId =
        (body['data'] as Map<String, dynamic>?)?['taskId']?.toString();
    if (taskId == null) {
      throw SunoApiException('Sunucudan taskId alınamadı: ${response.body}');
    }
    return taskId;
  }

  Future<({String title, String text})> _checkLyricsStatus(
    String taskId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/lyrics/record-info',
    ).replace(queryParameters: {'taskId': taskId});

    final response = await http.get(uri, headers: _headers);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || body['code'] != 200) {
      throw SunoApiException(
        _errorMessageFor(body['code']) ??
            body['msg']?.toString() ??
            'Söz durumu sorgulanamadı.',
      );
    }

    final data = body['data'] as Map<String, dynamic>? ?? {};
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
  // 2) ŞARKI (MÜZİK) ÜRETİMİ
  // ---------------------------------------------------------------------

  Future<String> _requestMusic({
    required String lyricsOrEmpty,
    required String style,
    required String title,
    required bool instrumental,
    String? vocalGender,
    int? durationSeconds,
    String callBackUrl = 'https://example.com/callback',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/generate');

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'customMode': true,
        'instrumental': instrumental,
        if (!instrumental) 'prompt': lyricsOrEmpty,
        'style': style,
        'title': title,
        'model': model,
        'callBackUrl': callBackUrl,
        if (vocalGender != null) 'vocalGender': vocalGender,
        if (durationSeconds != null) 'duration': durationSeconds,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || body['code'] != 200) {
      throw SunoApiException(
        _errorMessageFor(body['code']) ??
            body['msg']?.toString() ??
            'Bilinmeyen hata',
      );
    }

    final taskId =
        (body['data'] as Map<String, dynamic>?)?['taskId']?.toString();
    if (taskId == null) {
      throw SunoApiException('Sunucudan taskId alınamadı: ${response.body}');
    }
    return taskId;
  }

  Future<GenerationTask> checkStatus(String taskId) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/generate/record-info',
    ).replace(queryParameters: {'taskId': taskId});

    final response = await http.get(uri, headers: _headers);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || body['code'] != 200) {
      throw SunoApiException(
        _errorMessageFor(body['code']) ??
            body['msg']?.toString() ??
            'Bilinmeyen hata',
      );
    }

    return GenerationTask.fromJson(body);
  }

  // ---------------------------------------------------------------------
  // 3) DIŞARIYA AÇILAN ANA FONKSİYON
  // ---------------------------------------------------------------------

  Future<Song> generateAndWait(
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
  }) async {
    final style = [
      if (genre != null && genre.isNotEmpty) genre,
      if (mood != null && mood.isNotEmpty) mood,
    ].join(', ');

    String lyrics = '';
    String title = _titleFrom(descriptionPrompt);

    if (!instrumental) {
      onLyricsStart?.call();
      final result = await _generateLyricsAndWait(descriptionPrompt);
      lyrics = result.text;
      if (result.title.isNotEmpty) title = result.title;
    }

    final taskId = await _requestMusic(
      lyricsOrEmpty: lyrics,
      style: style.isEmpty ? 'Pop' : style,
      title: title,
      instrumental: instrumental,
      vocalGender: vocalGender,
      durationSeconds: durationSeconds,
    );

    final deadline = DateTime.now().add(timeout);
    int attempt = 0;

    while (DateTime.now().isBefore(deadline)) {
      attempt++;
      await Future.delayed(pollInterval);

      final task = await checkStatus(taskId);
      onTick?.call(task.status, attempt);

      if (task.status.isComplete && task.songs.isNotEmpty) {
        return task.songs.first;
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
    if (trimmed.isEmpty) return 'Adsız Şarkı';
    final words = trimmed.split(RegExp(r'\s+')).take(6).join(' ');
    return words.length > 80 ? words.substring(0, 80) : words;
  }

  String? _errorMessageFor(dynamic code) {
    switch (code) {
      case 400:
        return 'Geçersiz parametreler gönderildi.';
      case 401:
        return 'API key geçersiz veya eksik.';
      case 404:
        return 'İstek yapılan adres bulunamadı.';
      case 405:
        return 'İstek limiti aşıldı, biraz sonra tekrar deneyin.';
      case 413:
        return 'Prompt veya başlık çok uzun.';
      case 429:
        return 'Krediniz yetersiz. Hesabınıza kredi yüklemeniz gerekiyor.';
      case 430:
        return 'Çok sık istek gönderildi, lütfen biraz bekleyin.';
      case 455:
        return 'Sistem şu anda bakımda, daha sonra tekrar deneyin.';
      case 500:
        return 'Sunucu hatası oluştu.';
      default:
        return null;
    }
  }
}

class _StillPending implements Exception {}

class SunoApiException implements Exception {
  SunoApiException(this.message);
  final String message;

  @override
  String toString() => message;
}