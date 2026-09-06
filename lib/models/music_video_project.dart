import 'music_video_scene.dart';

class MusicVideoProject {
  MusicVideoProject({
    required this.projectId,
    required this.songTitle,
    required this.scenes,
    required this.estimatedCostUsd,
    required this.status,
    this.finalVideoUrl,
  });

  final String projectId;
  final String songTitle;
  final List<MusicVideoScene> scenes;
  final double estimatedCostUsd;

  /// storyboard_ready | generating | scenes_ready | scenes_failed | completed
  final String status;
  final String? finalVideoUrl;

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
      finalVideoUrl: json['finalVideoUrl']?.toString(),
    );
  }
}