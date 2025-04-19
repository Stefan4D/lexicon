class Scene {
  final int? id; // Nullable ID for auto-increment
  final int chapterId; // Foreign key to the chapter
  final String content; // Text content of the scene

  Scene({this.id, required this.chapterId, required this.content});
}
