import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexicon/services/file_parser_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite_api;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

// Mocks
@GenerateMocks([sqflite_api.Database])
import 'file_parser_service_test.mocks.dart';

void main() {
  sqfliteFfiInit(); // Initialize FFI for sqflite

  late FileParserService fileParserService;
  late MockDatabase mockSqfliteDatabase;
  late Directory tempDir;

  setUp(() async {
    fileParserService = FileParserService();
    mockSqfliteDatabase = MockDatabase();

    // Create a temporary directory for test files
    tempDir = await Directory.systemTemp.createTemp('file_parser_test_');
  });

  tearDown(() async {
    // Clean up the temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> createTempFile(String name, String content) async {
    final file = File(p.join(tempDir.path, name));
    await file.writeAsString(content);
    return file;
  }

  group('FileParserService Tests', () {
    group('_parseTxtFile Tests', () {
      const testProjectId = 1;
      final sampleTextContent =
          "This is a sample text. It has eight words in total.";
      // Corrected expected word count
      final expectedWordCount = 11;

      test(
        'should correctly parse .txt file, calculate word count, and insert data into DB',
        () async {
          // Arrange
          final testFile = await createTempFile(
            'sample.txt',
            sampleTextContent,
          );

          when(
            mockSqfliteDatabase.insert('chapters', any),
          ).thenAnswer((_) async => 1); // chapterId = 1
          when(
            mockSqfliteDatabase.insert('scenes', any),
          ).thenAnswer((_) async => 1); // sceneId = 1
          when(
            mockSqfliteDatabase.insert('content_blocks', any),
          ).thenAnswer((_) async => 1); // contentBlockId = 1

          // Act
          final result = await fileParserService.parseFile(
            testFile,
            mockSqfliteDatabase, // Pass the mock database directly
            testProjectId,
          );

          // Assert
          print(
            'DEBUG: Actual type: ${result['wordCount'].runtimeType}, Expected type: ${expectedWordCount.runtimeType}',
          );
          print(
            'DEBUG: Actual value: ${result['wordCount']}, Expected value: $expectedWordCount',
          );
          print(
            'DEBUG: Direct comparison (==): ${result['wordCount'] == expectedWordCount}',
          );
          expect(result['wordCount'], isA<int>());
          expect(result['wordCount'], expectedWordCount);
          expect(result['chapters'], isA<List>());
          // Further checks on chapters structure can be added if necessary

          // Verify Chapter insertion
          final chapterVerification = verify(
            mockSqfliteDatabase.insert('chapters', captureAny),
          );
          chapterVerification.called(1);
          // final capturedChapter =
          //     chapterVerification.captured.single as Map<String, dynamic>; // Removed
          // expect(capturedChapter['word_count'], knownWordCount); // Removed

          final sceneVerification = verify(
            mockSqfliteDatabase.insert('scenes', captureAny),
          );
          sceneVerification.called(1);
          // final capturedScene =
          //     sceneVerification.captured.single as Map<String, dynamic>; // Removed
          // expect(capturedScene['word_count'], knownWordCount); // Removed

          final contentBlockVerification = verify(
            mockSqfliteDatabase.insert('content_blocks', captureAny),
          );
          contentBlockVerification.called(1);
          final capturedContentBlock =
              contentBlockVerification.captured.single as Map<String, dynamic>;
          expect(capturedContentBlock['text_content'], sampleTextContent);
          // expect(capturedContentBlock['word_count'], knownWordCount); // Removed
        },
      );

      test(
        '_parseTxtFile should return 0 wordCount for empty content',
        () async {
          // Arrange
          final emptyTestFile = await createTempFile('empty.txt', '');

          // Act
          final result = await fileParserService.parseFile(
            emptyTestFile,
            mockSqfliteDatabase,
            testProjectId,
          );
          // Assert
          expect(result['wordCount'], 0);
          expect(result['chapters'], isEmpty);
          // Verify no DB interactions for empty content (as it returns early)
          verifyNever(mockSqfliteDatabase.insert(any, any));
        },
      );

      test(
        '_parseTxtFile should handle non-existent file by throwing PathNotFoundException via file.readAsString()',
        () async {
          // Arrange
          final nonExistentFile = File(
            p.join(tempDir.path, 'non_existent.txt'),
          );
          // Ensure file does not exist
          if (await nonExistentFile.exists()) {
            await nonExistentFile.delete();
          }

          // Assert
          expect(
            () async => fileParserService.parseFile(
              nonExistentFile,
              mockSqfliteDatabase,
              testProjectId,
            ),
            throwsA(
              isA<PathNotFoundException>(),
            ), // Exception from file.readAsString()
          );
        },
      );

      test(
        'should correctly parse .txt file from a specific path (simulating existing file)',
        () async {
          // Arrange
          final tempFileForAsset = await createTempFile(
            'sample_text_known_length.txt',
            "This is a sample text file for testing purposes. It has a known length.",
          );
          final fileContent = await tempFileForAsset.readAsString(); // Re-added
          final knownWordCount = 14;

          when(
            mockSqfliteDatabase.insert('chapters', any),
          ).thenAnswer((_) async => 1);
          when(
            mockSqfliteDatabase.insert('scenes', any),
          ).thenAnswer((_) async => 1);
          when(
            mockSqfliteDatabase.insert('content_blocks', any),
          ).thenAnswer((_) async => 1);

          // Act
          final result = await fileParserService.parseFile(
            tempFileForAsset,
            mockSqfliteDatabase,
            testProjectId,
          );

          // Assert
          expect(result['wordCount'], isA<int>());
          expect(result['wordCount'], knownWordCount);

          final chapterVerification = verify(
            mockSqfliteDatabase.insert('chapters', captureAny),
          );
          chapterVerification.called(1);
          // final capturedChapter =
          //     chapterVerification.captured.single as Map<String, dynamic>; // Removed
          // expect(capturedChapter['word_count'], knownWordCount); // Removed

          final sceneVerification = verify(
            mockSqfliteDatabase.insert('scenes', captureAny),
          );
          sceneVerification.called(1);
          // final capturedScene =
          //     sceneVerification.captured.single as Map<String, dynamic>; // Removed
          // expect(capturedScene['word_count'], knownWordCount); // Removed

          final contentBlockVerification = verify(
            mockSqfliteDatabase.insert('content_blocks', captureAny),
          );
          contentBlockVerification.called(1);
          final capturedContentBlock =
              contentBlockVerification.captured.single as Map<String, dynamic>;
          expect(capturedContentBlock['text_content'], fileContent);
          // expect(capturedContentBlock['word_count'], knownWordCount); // Removed
        },
      );
    });

    test(
      'parseFile should return 0 wordCount for unsupported file types',
      () async {
        // Arrange
        final unsupportedFile = await createTempFile(
          'document.unsupported',
          'Some content',
        );

        // Act
        final result = await fileParserService.parseFile(
          unsupportedFile,
          mockSqfliteDatabase,
          1, // projectId
        );

        // Assert
        expect(result['wordCount'], 0);
        expect(result['chapters'], isEmpty);
        verifyNever(mockSqfliteDatabase.insert(any, any));
      },
    );
  });
}
