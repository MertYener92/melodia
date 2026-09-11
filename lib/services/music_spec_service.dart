import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/music_spec.dart';

/// AI Müzik sihirbazının doğal-dil cevaplarını backend'deki Bedrock
/// (Claude) destekli `/music-spec` Lambda'sına gönderip, dönen
/// profesyonel [MusicSpec]'i çözümleyen servis.
///
/// Bu, mevcut [SunoApiService]'ten TAMAMEN AYRI bir backend'e (ayrı bir
/// API Gateway + Lambda) bağlanır; Suno akışına hiç dokunmaz. Aynı
/// Cognito idToken'ı kullanır.
class MusicSpecService {
  MusicSpecService({required this.apiUrl, required this.idTokenProvider});

  /// music-spec Lambda'sının TAM endpoint URL'i (alt yol eklenmez).
  final String apiUrl;
  final String? Function() idTokenProvider;

  Future<MusicSpec> interpret({
    required Map<String, dynamic> answers,
    String language = 'tr',
  }) async {
    final token = idTokenProvider();

    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'answers': answers, 'language': language}),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw MusicSpecException(
            'Sunucuya bağlanılamadı (zaman aşımı). Tekrar deneyin.',
          ),
        );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw MusicSpecException(
        body['message']?.toString() ??
            body['error']?.toString() ??
            'Müzik fikri yorumlanamadı.',
      );
    }

    return MusicSpec.fromJson(body);
  }
}