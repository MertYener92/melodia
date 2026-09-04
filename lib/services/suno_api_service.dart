import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

/// Kendi AWS backend'imize (Lambda + API Gateway) bağlanan servis.
///
/// ÖNEMLİ: Bu servis artık Suno API'ye DOĞRUDAN bağlanmıyor.
/// Suno API key'i telefon uygulamasında hiç bulunmuyor — sadece
/// AWS Secrets Manager'da, sunucu tarafında duruyor. Bu sayede:
///   1) Key hiçbir zaman tersine mühendislikle çalınamaz
///   2) Her kullanıcının aylık kotası backend'de takip edilir
///   3) Kota dolunca istek Suno'ya hiç gitmez, kredi harcanmaz
///
/// Her istek, kullanıcının Cognito girişinden aldığı idToken'ı
/// Authorization: Bearer <idToken> başlığıyla gönderir.
class SunoApiService {
  SunoApiService({
    required this.baseUrl,
    required this.idTokenProvider,
    this.model = 'V5_5',
  });

  /// Backend'in ApiUrl'i, örn:
  /// https://xxxxxxxx.execute-api.eu-north-1.amazonaws.com/prod
  final String baseUrl;

  /// Her istekte güncel Cognito idToken'ını döndüren fonksiyon.
  final String? Function() idTokenProvider;

  final String model;

  Map<String, String> get _headers {
    final token = idTokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return http
        .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
        .timeout(
          const Duration(seconds: 35),
          onTimeout: () => throw SunoApiException(
            'Sunucuya bağlanılamadı (zaman aşımı). '
            'İnternet bağlantınızı kontrol edip tekrar deneyin.',
          ),
        );
  }

  Future<http.Response> _get(String path, Map<String, String> query) {
    return http
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
        );
  }

  // ---------------------------------------------------------------------
  // 1) SÖZ ÜRETİMİ (yalnızca sözlü/instrumental olmayan şarkılar için)
  // ---------------------------------------------------------------------

  Future<String> _requestLyrics(String prompt) async {
    final trimmedPrompt =
        prompt.length > 200 ? prompt.substring(0, 200) : prompt;

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
  // 2) ŞARKI (MÜZİK) ÜRETİMİ — kota burada kontrol edilir
  // ---------------------------------------------------------------------

  Future<String> _requestMusic({
    required String lyricsOrEmpty,
    required String style,
    required String title,
    required bool instrumental,
    String? vocalGender,
    int? durationSeconds,
  }) async {
    final response = await _post('/generate', {
      'instrumental': instrumental,
      if (!instrumental) 'lyrics': lyricsOrEmpty,
      'style': style,
      'title': title,
      if (vocalGender != null) 'vocalGender': vocalGender,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    });

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 429) {
      throw SunoApiException(
        body['message']?.toString() ??
            'Bu ayki şarkı hakkınızı kullandınız.',
      );
    }
    if (response.statusCode != 200) {
      throw SunoApiException(
        body['message']?.toString() ?? body['error']?.toString() ?? 'Bilinmeyen hata',
      );
    }

    final taskId = body['taskId']?.toString();
    if (taskId == null) {
      throw SunoApiException('Sunucudan taskId alınamadı.');
    }
    return taskId;
  }

  Future<GenerationTask> checkStatus(String taskId) async {
    final response = await _get('/status', {'taskId': taskId});
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw SunoApiException(data['error']?.toString() ?? 'Bilinmeyen hata');
    }

    // GenerationTask.fromJson {'data': ...} şeklinde bekliyor,
    // backend'imiz doğrudan data objesini döndürüyor.
    return GenerationTask.fromJson({'data': data});
  }

  /// Uygulama açılışında "kalan hakkınız: X/Y" göstermek için.
  Future<({int used, int limit, int remaining, String plan})> getQuota() async {
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
    );
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
}

class _StillPending implements Exception {}

class SunoApiException implements Exception {
  SunoApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
