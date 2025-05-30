import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexicon/db/database_helper.dart';
import 'package:lexicon/models/chapter.dart';
import 'package:lexicon/models/content_block.dart';
import 'package:lexicon/models/scene.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart'; // Corrected import

final fileParserServiceProvider = Provider<FileParserService>((ref) {
  return FileParserService();
});

class FileParserService {
  // Table name constants
  static const String tableChapters = 'chapters';
  static const String tableScenes = 'scenes';
  static const String tableContentBlocks = 'content_blocks';

  Future<Map<String, dynamic>> parseFile(
    File file,
    Database projectDb,
    int projectId,
  ) async {
    final extension = p.extension(file.path).toLowerCase();
    switch (extension) {
      case '.txt':
        return _parseTxtFile(file, projectDb, projectId);
      // TODO: Add cases for .md, .docx, .scrivx
      default:
        print('Unsupported file type: $extension');
        // For now, return 0 words if unsupported, or throw an error
        // Or, perhaps the import service should check this before calling
        return {
          'wordCount': 0,
          'chapters': [],
        }; // Return 0 word count for unsupported files
    }
  }

  Future<Map<String, dynamic>> _parseTxtFile(
    File file,
    Database projectDb,
    int projectId,
  ) async {
    final content = await file.readAsString();
    if (content.isEmpty) {
      return {'wordCount': 0, 'chapters': []};
    }

    final totalWordCount = _calculateWordCount(content);
    final chaptersData = <Map<String, dynamic>>[];

    // Create Chapter
    final chapter = Chapter(
      // chapterId is auto-incremented by DB
      chapterTitle: 'Chapter 1', // Example title
      chapterOrder: 1,
    );
    Map<String, dynamic> chapterMap = chapter.toMap();
    chapterMap.remove('chapter_id'); // Remove for auto-increment

    final chapterId = await projectDb.insert(tableChapters, chapterMap);

    // Create Scene
    final scene = Scene(
      // sceneId is auto-incremented by DB
      sceneTitle: 'Scene 1', // Example title
      sceneOrder: 1,
      chapterId: chapterId, // FK
    );
    Map<String, dynamic> sceneMap = scene.toMap();
    sceneMap.remove('scene_id'); // Remove for auto-increment

    final sceneId = await projectDb.insert(tableScenes, sceneMap);

    // Create ContentBlock
    final contentBlock = ContentBlock(
      // blockId is auto-incremented by DB
      textContent: content,
      blockOrder: 1,
      blockType: 'prose', // Example type
      sceneId: sceneId, // FK
      chapterId: chapterId, // FK
    );
    Map<String, dynamic> contentBlockMap = contentBlock.toMap();
    contentBlockMap.remove('block_id'); // Remove for auto-increment

    await projectDb.insert(tableContentBlocks, contentBlockMap);

    // For now, returning a simplified structure.
    // This should eventually reflect the actual hierarchy.
    chaptersData.add({
      'chapter_title': chapter.chapterTitle,
      'scenes': [
        {
          'scene_title': scene.sceneTitle,
          'content_blocks': [contentBlock.toMap()],
        },
      ],
    });

    return {
      'wordCount': totalWordCount,
      'chapters': chaptersData, // This structure might need refinement
    };
  }

  /// Calculates the word count of a given text.
  ///
  /// Words are separated by one or more whitespace characters.
  int _calculateWordCount(String text) {
    if (text.trim().isEmpty) {
      return 0;
    }
    // Corrected RegExp to properly split by whitespace
    return text.trim().split(RegExp(r'\s+')).length;
  }
}
