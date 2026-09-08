import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/music_video_project.dart';

/// AI Video (Faz 1) için tamamen izole backend'e bağlanan servis.
/// Mevcut Suno/MusicSpec servislerinden bağımsız — sadece aynı Cognito
/// idToken'ı kullanır.
class MusicVideoService {
  MusicVideoService({required this.apiUrl, required this.idTokenProvider});

  /// melodia-video stack'inin HttpApi kök URL'i (alt yol yok, örn:
  /// https://xxxx.execute-api.eu-north-1.amazonaws.com).
  final String apiUrl;
  final String? Function() idTokenProvider;

  Map<String, String> get _headers {
    final token = idTokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Kullanıcının tüm klip projelerini getirir (Kütüphane sekmesi için).
  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final response = await http.get(
      Uri.parse('$apiUrl/video/projects'),
      headers: _headers,
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw MusicVideoException(body['error']?.toString() ?? 'Klipler yüklenemedi.');
    }
    final projects = body['projects'] as List<dynamic>? ?? [];
    return projects.cast<Map<String, dynamic>>();
  }

  /// Bir klip projesini kalıcı olarak siler (DynamoDB + S3'teki
  /// fotoğraflar ve final video).
  Future<void> deleteProject(String projectId) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/video/projects/$projectId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw MusicVideoException('Klip silinemedi.');
    }
  }

  /// Fotoğrafı önce presigned URL alıp, sonra doğrudan S3'e yükler.
  /// Döndürdüğü "key" değeri createProject'e gönderilir.
  Future<String> uploadPhoto({
    required String slot, // 'front' | 'left' | 'right'
    required Uint8List bytes,
    required String contentType,
  }) async {
    final urlResponse = await http.post(
      Uri.parse('$apiUrl/video/upload-url'),
      headers: _headers,
      body: jsonEncode({'slot': slot, 'contentType': contentType}),
    );
    if (urlResponse.statusCode != 200) {
      throw MusicVideoException('Fotoğraf için yükleme adresi alınamadı.');
    }
    final body = jsonDecode(urlResponse.body) as Map<String, dynamic>;
    final uploadUrl = body['uploadUrl'] as String;
    final key = body['key'] as String;

    final putResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (putResponse.statusCode != 200) {
      throw MusicVideoException('Fotoğraf yüklenemedi.');
    }
    return key;
  }

  Future<MusicVideoProject> createProject({
    required String songId,
    required String songTitle,
    required String songAudioUrl,
    required num songDurationSeconds,
    required String genre,
    required String mood,
    required String prompt,
    required String style,
    required String concept,
    required Map<String, String> photoKeys, // front/left/right
  }) async {
    final response = await http.post(
      Uri.parse('$apiUrl/video/projects'),
      headers: _headers,
      body: jsonEncode({
        'songId': songId,
        'songTitle': songTitle,
        'songAudioUrl': songAudioUrl,
        'songDurationSeconds': songDurationSeconds,
        'genre': genre,
        'mood': mood,
        'prompt': prompt,
        'style': style,
        'concept': concept,
        'photoKeys': photoKeys,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw MusicVideoException(body['error']?.toString() ?? 'Klip planı oluşturulamadı.');
    }
    return MusicVideoProject.fromJson(body);
  }

  Future<void> startGeneration(String projectId) async {
    final response = await http.post(
      Uri.parse('$apiUrl/video/projects/$projectId/generate'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw MusicVideoException('Klip üretimi başlatılamadı.');
    }
  }

  Future<MusicVideoProject> getStatus(String projectId) async {
    final response = await http.get(
      Uri.parse('$apiUrl/video/projects/$projectId'),
      headers: _headers,
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw MusicVideoException(body['error']?.toString() ?? 'Durum alınamadı.');
    }
    return MusicVideoProject.fromJson(body);
  }

  /// Video birleştirmeyi ARKA PLANDA başlatır (API Gateway'in ~30 saniyelik
  /// sabit yanıt süresi sınırını aşan bu işlem, senkron beklenmiyor).
  /// Sonuç durumu [getStatus] ile polling yapılarak alınmalı; video hazır
  /// olduğunda oynatma linki için [getVideoPlayUrl] çağrılmalı.
  Future<void> startAssembly(String projectId) async {
    final response = await http.post(
      Uri.parse('$apiUrl/video/projects/$projectId/assemble'),
      headers: _headers,
    );
    if (response.statusCode != 202 && response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw MusicVideoException(body['error']?.toString() ?? 'Klip birleştirme başlatılamadı.');
    }
  }

  /// YENİ: Video oynatılmak istendiğinde çağrılır. DB'de sabit bir URL
  /// saklanmadığı için (eski sistemde "ExpiredToken" hatasına sebep
  /// oluyordu), her oynatma denemesinden hemen önce burası çağrılıp
  /// taze, ~1 saat geçerli bir CloudFront signed URL alınmalı. Bu URL'i
  /// önbelleğe alıp saatler sonra tekrar kullanma -- süresi dolmuş olabilir.
  Future<String> getVideoPlayUrl(String projectId) async {
    final response = await http.get(
      Uri.parse('$apiUrl/video/projects/$projectId/play-url'),
      headers: _headers,
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 409) {
      throw MusicVideoException('Video henüz hazır değil (durum: ${body['status']}).');
    }
    if (response.statusCode != 200) {
      throw MusicVideoException(body['error']?.toString() ?? 'Video linki alınamadı.');
    }
    return body['playUrl'] as String;
  }
}

class MusicVideoException implements Exception {
  MusicVideoException(this.message);
  final String message;
  @override
  String toString() => message;
}