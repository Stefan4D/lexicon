import 'package:flutter_test/flutter_test.dart';
import 'package:lexicon/models/chapter.dart';

void main() {
  group('Chapter Model Tests', () {
    test('toMap() and fromMap() should work correctly', () {
      final originalChapter = Chapter(
        chapterId: 1,
        chapterOrder: 1,
        chapterTitle: 'The Beginning',
      );

      final chapterMap = originalChapter.toMap();
      final chapterFromMap = Chapter.fromMap(chapterMap);

      expect(chapterFromMap.chapterId, originalChapter.chapterId);
      expect(chapterFromMap.chapterOrder, originalChapter.chapterOrder);
      expect(chapterFromMap.chapterTitle, originalChapter.chapterTitle);

      // Verify that fields removed from the model are not present in the map
      expect(chapterMap.containsKey('project_id'), isFalse);
      expect(chapterMap.containsKey('chapter_description'), isFalse);
      expect(chapterMap.containsKey('word_count'), isFalse);
      expect(chapterMap.containsKey('created_date'), isFalse);
      expect(chapterMap.containsKey('last_modified_date'), isFalse);
      expect(chapterMap.containsKey('custom_fields'), isFalse);
    });

    test('copyWith should work correctly', () {
      final originalChapter = Chapter(
        chapterId: 1,
        chapterOrder: 1,
        chapterTitle: 'Original Title',
      );

      final updatedChapter = originalChapter.copyWith(
        chapterTitle: 'Updated Title',
        chapterOrder: 2,
      );

      expect(updatedChapter.chapterId, originalChapter.chapterId);
      expect(updatedChapter.chapterOrder, 2);
      expect(updatedChapter.chapterTitle, 'Updated Title');
    });
  });
}
