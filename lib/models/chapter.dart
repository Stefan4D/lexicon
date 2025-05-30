class Chapter {
  final int? chapterId;
  final String? chapterTitle; // Nullable as per schema
  final int? chapterOrder; // Nullable as per schema

  Chapter({this.chapterId, this.chapterTitle, this.chapterOrder});

  // Convert a Chapter object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'chapter_id': chapterId,
      'chapter_title': chapterTitle,
      'chapter_order': chapterOrder,
    };
  }

  // Convert a Map object into a Chapter object
  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      chapterId: map['chapter_id'] as int?,
      chapterTitle: map['chapter_title'] as String?,
      chapterOrder: map['chapter_order'] as int?,
    );
  }

  // Convert a Chapter object into a JSON object
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // Convert a JSON object into a Chapter object
  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter.fromMap(json);
  }

  // Convert a list of Chapter objects into a JSON array
  static List<Map<String, dynamic>> toJsonList(List<Chapter> chapters) {
    return chapters.map((chapter) => chapter.toJson()).toList();
  }

  // Convert a JSON array into a list of Chapter objects
  static List<Chapter> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => Chapter.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() {
    return 'Chapter{chapterId: $chapterId, chapterTitle: $chapterTitle, chapterOrder: $chapterOrder}';
  }

  Chapter copyWith({int? chapterId, String? chapterTitle, int? chapterOrder}) {
    return Chapter(
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterOrder: chapterOrder ?? this.chapterOrder,
    );
  }
}
