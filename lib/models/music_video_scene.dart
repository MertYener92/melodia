class MusicVideoScene {
  MusicVideoScene({
    required this.sceneId,
    required this.order,
    required this.startTime,
    required this.duration,
    required this.prompt,
    required this.sceneType,
    required this.status,
    this.videoUrl,
    this.estimatedCostUsd = 0,
  });

  final String sceneId;
  final int order;
  final num startTime;
  final num duration;
  final String prompt;

  /// BROLL | ENVIRONMENT | STATIC_MOTION | PERFORMANCE | CHARACTER
  final String sceneType;

  /// pending | processing | completed | failed
  final String status;
  final String? videoUrl;
  final double estimatedCostUsd;

  factory MusicVideoScene.fromJson(Map<String, dynamic> json) {
    return MusicVideoScene(
      sceneId: json['sceneId']?.toString() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      startTime: (json['startTime'] as num?) ?? 0,
      duration: (json['duration'] as num?) ?? 8,
      prompt: json['prompt']?.toString() ?? '',
      sceneType: json['sceneType']?.toString() ?? 'BROLL',
      status: json['status']?.toString() ?? 'pending',
      videoUrl: json['videoUrl']?.toString(),
      estimatedCostUsd: (json['estimatedCostUsd'] as num?)?.toDouble() ?? 0,
    );
  }
}