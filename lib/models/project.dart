class Project {
  final int? id; // Nullable ID for auto-increment
  final String name; // Name of the project

  Project({this.id, required this.name});

  // Convert a Project object into a Map object
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  // Convert a Map object into a Project object
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(id: map['id'], name: map['name']);
  }
  // Convert a Project object into a JSON object
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  // Convert a JSON object into a Project object
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(id: json['id'], name: json['name']);
  }
  // Convert a list of Project objects into a JSON array
  static List<Map<String, dynamic>> toJsonList(List<Project> projects) {
    return projects.map((project) => project.toJson()).toList();
  }

  // Convert a JSON array into a list of Project objects
  static List<Project> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Project.fromJson(json)).toList();
  }
}
