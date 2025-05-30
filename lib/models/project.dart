class Project {
  final int? projectId;
  final String projectName;
  final String sourcePath;
  final String dbPath;
  final int? seriesId; // Nullable foreign key to Series
  final DateTime lastImportedAt;
  final DateTime createdAt;
  final int wordCount; // Added field

  Project({
    this.projectId,
    required this.projectName,
    required this.sourcePath,
    required this.dbPath,
    this.seriesId,
    required this.lastImportedAt,
    required this.createdAt,
    this.wordCount = 0, // Added with default value
  });

  // Convert a Project object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'project_id': projectId,
      'project_name': projectName,
      'source_path': sourcePath,
      'db_path': dbPath,
      'series_id': seriesId,
      'last_imported_at': lastImportedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'word_count': wordCount, // Added
    };
  }

  // Convert a Map object into a Project object
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      projectId: map['project_id'] as int?,
      projectName: map['project_name'] as String,
      sourcePath: map['source_path'] as String,
      dbPath: map['db_path'] as String,
      seriesId: map['series_id'] as int?,
      lastImportedAt: DateTime.parse(map['last_imported_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      wordCount:
          map['word_count'] as int? ?? 0, // Added with default if null from DB
    );
  }

  // Convert a Project object into a JSON object (alias for toMap for consistency)
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // Convert a JSON object into a Project object (alias for fromMap for consistency)
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project.fromMap(json);
  }

  // Convert a list of Project objects into a JSON array
  static List<Map<String, dynamic>> toJsonList(List<Project> projects) {
    return projects.map((project) => project.toJson()).toList();
  }

  // Convert a JSON array into a list of Project objects
  static List<Project> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => Project.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() {
    return 'Project{projectId: $projectId, projectName: $projectName, sourcePath: $sourcePath, dbPath: $dbPath, seriesId: $seriesId, lastImportedAt: $lastImportedAt, createdAt: $createdAt, wordCount: $wordCount}'; // Updated
  }

  // It's good practice to include copyWith for immutable objects if you plan to modify them
  Project copyWith({
    int? projectId,
    String? projectName,
    String? sourcePath,
    String? dbPath,
    int? seriesId,
    DateTime? lastImportedAt,
    DateTime? createdAt,
    int? wordCount, // Added
  }) {
    return Project(
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      sourcePath: sourcePath ?? this.sourcePath,
      dbPath: dbPath ?? this.dbPath,
      seriesId: seriesId ?? this.seriesId,
      lastImportedAt: lastImportedAt ?? this.lastImportedAt,
      createdAt: createdAt ?? this.createdAt,
      wordCount: wordCount ?? this.wordCount, // Added
    );
  }
}
