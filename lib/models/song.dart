/// sunoapi.org'un /api/v1/generate/record-info yanıtındaki
/// "sunoData" dizisi içindeki tek bir şarkıyı temsil eder.
class Song {
  final String id;
  final String title;
  final String prompt;
  final String audioUrl;
  final String streamAudioUrl;
  final String imageUrl;
  final double? duration;

  Song({
    required this.id,
    required this.title,
    required this.prompt,
    required this.audioUrl,
    required this.streamAudioUrl,
    required this.imageUrl,
    this.duration,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Adsız Şarkı',
      prompt: json['prompt']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString() ?? '',
      streamAudioUrl: json['streamAudioUrl']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      duration: (json['duration'] as num?)?.toDouble(),
    );
  }
}

/// /api/v1/generate/record-info yanıtındaki üst seviye görev durumu.
enum TaskStatus {
  pending,
  textSuccess,
  firstSuccess,
  success,
  createTaskFailed,
  generateAudioFailed,
  callbackException,
  sensitiveWordError,
  unknown;

  static TaskStatus fromString(String? value) {
    switch (value) {
      case 'PENDING':
        return TaskStatus.pending;
      case 'TEXT_SUCCESS':
        return TaskStatus.textSuccess;
      case 'FIRST_SUCCESS':
        return TaskStatus.firstSuccess;
      case 'SUCCESS':
        return TaskStatus.success;
      case 'CREATE_TASK_FAILED':
        return TaskStatus.createTaskFailed;
      case 'GENERATE_AUDIO_FAILED':
        return TaskStatus.generateAudioFailed;
      case 'CALLBACK_EXCEPTION':
        return TaskStatus.callbackException;
      case 'SENSITIVE_WORD_ERROR':
        return TaskStatus.sensitiveWordError;
      default:
        return TaskStatus.unknown;
    }
  }

  bool get isFailed =>
      this == TaskStatus.createTaskFailed ||
      this == TaskStatus.generateAudioFailed ||
      this == TaskStatus.callbackException ||
      this == TaskStatus.sensitiveWordError;

  bool get isComplete => this == TaskStatus.success;
}

/// Bir üretim görevinin tam durumu: status + varsa üretilen şarkılar.
class GenerationTask {
  final TaskStatus status;
  final List<Song> songs;
  final String? errorMessage;

  GenerationTask({
    required this.status,
    required this.songs,
    this.errorMessage,
  });

  factory GenerationTask.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final status = TaskStatus.fromString(data['status']?.toString());

    final response = data['response'] as Map<String, dynamic>?;
    final sunoData = response?['sunoData'] as List<dynamic>? ?? [];

    return GenerationTask(
      status: status,
      songs: sunoData
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
      errorMessage: data['errorMessage']?.toString(),
    );
  }
}