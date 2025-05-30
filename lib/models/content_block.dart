class ContentBlock {
  final int? blockId;
  final String textContent;
  final int blockOrder;
  final String? blockType;
  final int? sceneId; // Nullable FK to scenes
  final int? chapterId; // Nullable FK to chapters

  ContentBlock({
    this.blockId,
    required this.textContent,
    required this.blockOrder,
    this.blockType,
    this.sceneId,
    this.chapterId,
  });

  Map<String, dynamic> toMap() {
    return {
      'block_id': blockId,
      'text_content': textContent,
      'block_order': blockOrder,
      'block_type': blockType,
      'scene_id': sceneId,
      'chapter_id': chapterId,
    };
  }

  factory ContentBlock.fromMap(Map<String, dynamic> map) {
    return ContentBlock(
      blockId: map['block_id'] as int?,
      textContent: map['text_content'] as String,
      blockOrder: map['block_order'] as int,
      blockType: map['block_type'] as String?,
      sceneId: map['scene_id'] as int?,
      chapterId: map['chapter_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock.fromMap(json);
  }

  static List<Map<String, dynamic>> toJsonList(List<ContentBlock> blocks) {
    return blocks.map((block) => block.toJson()).toList();
  }

  static List<ContentBlock> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => ContentBlock.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() {
    return 'ContentBlock{blockId: $blockId, textContent.length: ${textContent.length}, blockOrder: $blockOrder, blockType: $blockType, sceneId: $sceneId, chapterId: $chapterId}';
  }

  ContentBlock copyWith({
    int? blockId,
    String? textContent,
    int? blockOrder,
    String? blockType,
    int? sceneId,
    int? chapterId,
  }) {
    return ContentBlock(
      blockId: blockId ?? this.blockId,
      textContent: textContent ?? this.textContent,
      blockOrder: blockOrder ?? this.blockOrder,
      blockType: blockType ?? this.blockType,
      sceneId: sceneId ?? this.sceneId,
      chapterId: chapterId ?? this.chapterId,
    );
  }
}
