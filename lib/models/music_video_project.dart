import 'music_video_scene.dart';

class MusicVideoProject {
  MusicVideoProject({
    required this.projectId,
    required this.songTitle,
    required this.scenes,
    required this.estimatedCostUsd,
    required this.status,
    this.finalVideoKey,
    this.concept,
    this.isFavorite = false,
    this.note,
  });

  final String projectId;
  final String songTitle;
  final List<MusicVideoScene> scenes;
  final double estimatedCostUsd;

  /// storyboard_ready | generating | scenes_ready | scenes_failed | completed | assembly_failed
  final String status;

  /// DİKKAT: Bu artık oynatılabilir bir URL DEĞİL, S3 object key'i
  /// (örn. "final-videos/{projectId}.mp4"). Videoyu oynatmadan hemen
  /// önce MusicVideoService.getVideoPlayUrl(projectId) çağrılıp taze
  /// bir CloudFront signed URL alınmalı -- eski sistemde burada sabit
  /// bir "finalVideoUrl" saklanıyordu ve birkaç saat içinde
  /// "ExpiredToken" hatasıyla ölüyordu.
  final String? finalVideoKey;

  /// Kullanıcının klip oluştururken girdiği serbest konsept metni --
  /// oynatma ekranında video hakkında bilgi olarak gösterilir.
  final String? concept;

  /// YENİ: kullanıcı bu klibi favorilerine eklediyse true.
  final bool isFavorite;

  /// YENİ: kullanıcının klip için eklediği serbest not.
  final String? note;

  bool get hasFinalVideo => finalVideoKey != null;

  int get completedSceneCount => scenes.where((s) => s.status == 'completed').length;
  int get failedSceneCount => scenes.where((s) => s.status == 'failed').length;
  bool get allScenesDone => scenes.every((s) => s.status == 'completed' || s.status == 'failed');

  factory MusicVideoProject.fromJson(Map<String, dynamic> json) {
    final rawScenes = json['scenes'] as List<dynamic>? ?? [];
    return MusicVideoProject(
      projectId: json['projectId']?.toString() ?? '',
      songTitle: json['songTitle']?.toString() ?? '',
      scenes: rawScenes
          .map((e) => MusicVideoScene.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedCostUsd: (json['estimatedCostUsd'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'storyboard_ready',
      finalVideoKey: json['finalVideoKey']?.toString(),
      concept: json['concept']?.toString(),
      isFavorite: json['isFavorite'] == true,
      note: json['note']?.toString(),
    );
  }
}