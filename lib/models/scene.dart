class Scene {
  final int? sceneId;
  final String? sceneTitle; // Nullable as per schema
  final int? sceneOrder; // Nullable as per schema
  final int? chapterId; // Nullable foreign key to Chapter

  Scene({this.sceneId, this.sceneTitle, this.sceneOrder, this.chapterId});

  Map<String, dynamic> toMap() {
    return {
      'scene_id': sceneId,
      'scene_title': sceneTitle,
      'scene_order': sceneOrder,
      'chapter_id': chapterId,
    };
  }

  factory Scene.fromMap(Map<String, dynamic> map) {
    return Scene(
      sceneId: map['scene_id'] as int?,
      sceneTitle: map['scene_title'] as String?,
      sceneOrder: map['scene_order'] as int?,
      chapterId: map['chapter_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene.fromMap(json);
  }

  static List<Map<String, dynamic>> toJsonList(List<Scene> scenes) {
    return scenes.map((scene) => scene.toJson()).toList();
  }

  static List<Scene> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => Scene.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() {
    return 'Scene{sceneId: $sceneId, sceneTitle: $sceneTitle, sceneOrder: $sceneOrder, chapterId: $chapterId}';
  }

  Scene copyWith({
    int? sceneId,
    String? sceneTitle,
    int? sceneOrder,
    int? chapterId,
  }) {
    return Scene(
      sceneId: sceneId ?? this.sceneId,
      sceneTitle: sceneTitle ?? this.sceneTitle,
      sceneOrder: sceneOrder ?? this.sceneOrder,
      chapterId: chapterId ?? this.chapterId,
    );
  }
}
