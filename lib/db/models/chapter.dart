class Chapter {
  final int? id; // Nullable ID for auto-increment
  final int projectId; // Foreign key to the project

  Chapter({this.id, required this.projectId});
  // Convert a Chapter object into a Map object
  Map<String, dynamic> toMap() {
    return {'id': id, 'project_id': projectId};
  }

  // Convert a Map object into a Chapter object
  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(id: map['id'], projectId: map['project_id']);
  }
  // Convert a Chapter object into a JSON object
  Map<String, dynamic> toJson() {
    return {'id': id, 'project_id': projectId};
  }

  // Convert a JSON object into a Chapter object
  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(id: json['id'], projectId: json['project_id']);
  }
  // Convert a list of Chapter objects into a JSON array
  static List<Map<String, dynamic>> toJsonList(List<Chapter> chapters) {
    return chapters.map((chapter) => chapter.toJson()).toList();
  }

  // Convert a JSON array into a list of Chapter objects
  static List<Chapter> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Chapter.fromJson(json)).toList();
  }
}
