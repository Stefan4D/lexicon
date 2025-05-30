import 'package:flutter_test/flutter_test.dart';
import 'package:lexicon/models/content_block.dart';

void main() {
  group('ContentBlock Model Tests', () {
    test('toMap() and fromMap() should work correctly', () {
      final originalContentBlock = ContentBlock(
        blockId: 1,
        sceneId: 301,
        chapterId: 201,
        blockType: 'paragraph',
        blockOrder: 1,
        textContent: 'This is the first paragraph of the scene.',
      );

      final contentBlockMap = originalContentBlock.toMap();
      final contentBlockFromMap = ContentBlock.fromMap(contentBlockMap);

      expect(contentBlockFromMap.blockId, originalContentBlock.blockId);
      expect(contentBlockFromMap.sceneId, originalContentBlock.sceneId);
      expect(contentBlockFromMap.chapterId, originalContentBlock.chapterId);
      expect(contentBlockFromMap.blockType, originalContentBlock.blockType);
      expect(contentBlockFromMap.blockOrder, originalContentBlock.blockOrder);
      expect(contentBlockFromMap.textContent, originalContentBlock.textContent);
    });

    test('copyWith should work correctly', () {
      final originalContentBlock = ContentBlock(
        blockId: 1,
        sceneId: 301,
        chapterId: 201,
        blockType: 'paragraph',
        blockOrder: 1,
        textContent: 'Original content.',
      );

      final updatedContentBlock = originalContentBlock.copyWith(
        textContent: 'Updated content.',
        blockOrder: 2,
      );

      expect(updatedContentBlock.blockId, originalContentBlock.blockId);
      expect(updatedContentBlock.sceneId, originalContentBlock.sceneId);
      expect(updatedContentBlock.chapterId, originalContentBlock.chapterId);
      expect(updatedContentBlock.blockType, originalContentBlock.blockType);
      expect(updatedContentBlock.blockOrder, 2);
      expect(updatedContentBlock.textContent, 'Updated content.');
    });
  });
}
