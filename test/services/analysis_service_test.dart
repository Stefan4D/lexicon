import 'package:flutter_test/flutter_test.dart';
import 'package:lexicon/services/analysis_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite_api;

// Mocks
@GenerateMocks([sqflite_api.Database])
import 'analysis_service_test.mocks.dart';

void main() {
  late AnalysisService analysisService;
  late MockDatabase mockDatabase;

  setUp(() {
    analysisService = AnalysisService();
    mockDatabase = MockDatabase();
  });

  group('AnalysisService Tests', () {
    group('_tokenizeText Tests', () {
      // Accessing private method for testing via a public wrapper or by testing through public methods.
      // For simplicity in this example, we'll assume we can test its logic
      // by providing various inputs to a conceptual public wrapper if needed,
      // or by ensuring public methods that use it are well-tested.
      // Direct testing of private methods is often discouraged, but their logic must be covered.

      // The logic of _tokenizeText is tested via getWordFrequencies and getTopNWords.

      test('should return empty list for empty string', () {
        // We can't directly test _tokenizeText output here without refactoring or specific test setup.
        // So, we'll focus on testing its effects via public methods.
        // For now, let's assume _tokenizeText is tested via getWordFrequencies.
        // If _getAllTextForProject returns "", _tokenizeText("") should be []
        when(mockDatabase.query('content_blocks')).thenAnswer((_) async => []);
        expectLater(
          analysisService.getWordFrequencies(mockDatabase),
          completion(isEmpty),
        );
      });

      test('should tokenize simple text correctly', () {
        const text = "hello world";
        // Expected: ['hello', 'world']
        // Test via getWordFrequencies
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': text},
          ],
        );
        expectLater(
          analysisService.getWordFrequencies(mockDatabase),
          completion(equals({'hello': 1, 'world': 1})),
        );
      });

      test('should handle mixed case and convert to lowercase', () {
        const text = "Hello World HELLO";
        // Expected: ['hello', 'world', 'hello']
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': text},
          ],
        );
        expectLater(
          analysisService.getWordFrequencies(mockDatabase),
          completion(equals({'hello': 2, 'world': 1})),
        );
      });

      test('should handle punctuation and special characters', () {
        const text = "word1, word2! word3? 'word4' \"word5\" (word6).";
        // Expected: ['word1', 'word2', 'word3', 'word4', 'word5', 'word6']
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': text},
          ],
        );
        expectLater(
          analysisService.getWordFrequencies(mockDatabase),
          completion(
            equals({
              'word1': 1,
              'word2': 1,
              'word3': 1,
              'word4': 1,
              'word5': 1,
              'word6': 1,
            }),
          ),
        );
      });

      test('should handle contractions and possessives correctly', () {
        const text = "don't can't it's o'malley author's";
        // Expected: ["don't", "can't", "it's", "o'malley", "author's"]
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': text},
          ],
        );
        expectLater(
          analysisService.getWordFrequencies(mockDatabase),
          completion(
            equals({
              "don't": 1,
              "can't": 1,
              "it's": 1,
              "o'malley": 1,
              "author's": 1,
            }),
          ),
        );
      });

      test(
        'should handle words with leading/trailing apostrophes from quotes',
        () {
          const text = "'quoted' word and 'another'";
          // Expected based on current regex: ["'quoted'", "word", "and", "'another'"] -> then frequencies
          // Current regex: r"[a-zA-Z0-9]+(?:['’][a-zA-Z0-9]+)*"
          // 'quoted' -> quoted
          // 'another' -> another
          when(mockDatabase.query('content_blocks')).thenAnswer(
            (_) async => [
              {'text_content': text},
            ],
          );
          expectLater(
            analysisService.getWordFrequencies(mockDatabase),
            completion(
              equals({"quoted": 1, "word": 1, "and": 1, "another": 1}),
            ),
          );
        },
      );

      test('should handle numbers as words', () {
        const text = "word 123 number";
        // Expected: ['word', '123', 'number']
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': text},
          ],
        );
        expectLater(
          analysisService.getWordFrequencies(mockDatabase),
          completion(equals({'word': 1, '123': 1, 'number': 1})),
        );
      });

      test('should handle text with multiple spaces between words', () {
        const text = "word1   word2";
        // Expected: ['word1', 'word2']
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': text},
          ],
        );
        expectLater(
          analysisService.getWordFrequencies(mockDatabase),
          completion(equals({'word1': 1, 'word2': 1})),
        );
      });

      test('should handle leading/trailing spaces in the input string', () {
        const text = "  leading and trailing spaces  ";
        // Expected: ['leading', 'and', 'trailing', 'spaces']
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': text},
          ],
        );
        expectLater(
          analysisService.getWordFrequencies(mockDatabase),
          completion(
            equals({'leading': 1, 'and': 1, 'trailing': 1, 'spaces': 1}),
          ),
        );
      });
    });

    group('_getAllTextForProject Tests', () {
      test('should return empty string if no content blocks', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer((_) async => []);
        final result = await analysisService.getWordFrequencies(
          mockDatabase,
        ); // Calls _getAllTextForProject
        expect(result, isEmpty);
      });

      test(
        'should concatenate text_content from multiple blocks with newlines',
        () async {
          when(mockDatabase.query('content_blocks')).thenAnswer(
            (_) async => [
              {'text_content': 'First line.'},
              {'text_content': 'Second line.'},
            ],
          );
          // This test implicitly tests _getAllTextForProject through getWordFrequencies
          final frequencies = await analysisService.getWordFrequencies(
            mockDatabase,
          );
          expect(frequencies, {'first': 1, 'line': 2, 'second': 1});
        },
      );
    });

    group('getWordFrequencies Tests', () {
      test('should return empty map for empty text', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer((_) async => []);
        final frequencies = await analysisService.getWordFrequencies(
          mockDatabase,
        );
        expect(frequencies, isEmpty);
      });

      test('should return correct frequencies for given text', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': "apple banana apple orange banana apple"},
          ],
        );
        final frequencies = await analysisService.getWordFrequencies(
          mockDatabase,
        );
        expect(frequencies, {'apple': 3, 'banana': 2, 'orange': 1});
      });

      test(
        'should return correct frequencies with default stop words',
        () async {
          when(mockDatabase.query('content_blocks')).thenAnswer(
            (_) async => [
              {'text_content': "the apple and the banana are sweet"},
            ],
          );
          // Default stop words include "the", "and", "are"
          final frequencies = await analysisService.getWordFrequencies(
            mockDatabase,
            useStopWords: true,
          );
          expect(frequencies, {'apple': 1, 'banana': 1, 'sweet': 1});
        },
      );

      test(
        'should return correct frequencies with custom stop words',
        () async {
          when(mockDatabase.query('content_blocks')).thenAnswer(
            (_) async => [
              {'text_content': "apple banana orange grape"},
            ],
          );
          final frequencies = await analysisService.getWordFrequencies(
            mockDatabase,
            useStopWords: true,
            customStopWords: ['banana', 'grape'],
          );
          expect(frequencies, {'apple': 1, 'orange': 1});
        },
      );

      test('should ignore case in custom stop words', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': "Apple Banana Orange Grape"},
          ],
        );
        final frequencies = await analysisService.getWordFrequencies(
          mockDatabase,
          useStopWords: true,
          customStopWords: ['BaNaNa', 'GRAPE'],
        );
        expect(frequencies, {'apple': 1, 'orange': 1});
      });

      test('should handle empty custom stop words list', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': "apple banana the and"},
          ],
        );
        // Expect default stop words to be used if custom list is empty and useStopWords is true
        final frequencies = await analysisService.getWordFrequencies(
          mockDatabase,
          useStopWords: true,
          customStopWords:
              [], // Empty list, should fall back to defaultStopWords
        );
        // defaultStopWords contains 'the', 'and'
        expect(frequencies, {'apple': 1, 'banana': 1});
      });

      test(
        'should not filter if useStopWords is false, even with custom list',
        () async {
          when(mockDatabase.query('content_blocks')).thenAnswer(
            (_) async => [
              {'text_content': "apple banana orange grape"},
            ],
          );
          final frequencies = await analysisService.getWordFrequencies(
            mockDatabase,
            useStopWords: false,
            customStopWords: ['banana', 'grape'],
          );
          expect(frequencies, {
            'apple': 1,
            'banana': 1,
            'orange': 1,
            'grape': 1,
          });
        },
      );
    });

    group('getTopNWords Tests', () {
      test('should return empty map if frequencies are empty', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer((_) async => []);
        final topN = await analysisService.getTopNWords(mockDatabase, 5);
        expect(topN, isEmpty);
      });

      test('should return top N words sorted by frequency', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {
              'text_content':
                  "one two two three three three four four four four five five five five five",
            },
          ],
        );
        final topN = await analysisService.getTopNWords(mockDatabase, 3);
        expect(topN, {'five': 5, 'four': 4, 'three': 3});
        // Check order if it matters (Map in Dart preserves insertion order for some types)
        // For this test, content is enough.
      });

      test(
        'should return all words if N is larger than unique word count',
        () async {
          when(mockDatabase.query('content_blocks')).thenAnswer(
            (_) async => [
              {'text_content': "apple banana apple"},
            ],
          );
          final topN = await analysisService.getTopNWords(mockDatabase, 5);
          expect(topN, {'apple': 2, 'banana': 1});
        },
      );

      test('should handle N=0 correctly', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': "apple banana apple"},
          ],
        );
        final topN = await analysisService.getTopNWords(mockDatabase, 0);
        expect(topN, isEmpty);
      });

      test('should handle N=1 correctly', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': "apple banana apple orange orange orange"},
          ],
        );
        final topN = await analysisService.getTopNWords(mockDatabase, 1);
        expect(topN, {'orange': 3});
      });

      test('should return top N words with default stop words', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {
              'text_content':
                  "the apple and the banana are sweet apple is good the sweet fruit",
            },
          ],
        );
        // "the", "and", "are", "is" are common stop words
        // Frequencies without stop words: the:3, apple:2, and:1, banana:1, are:1, sweet:2, is:1, good:1, fruit:1
        // Frequencies with default stop words: apple:2, banana:1, sweet:2, good:1, fruit:1
        final topN = await analysisService.getTopNWords(
          mockDatabase,
          3,
          useStopWords: true,
        );
        // Expected: {'apple': 2, 'sweet': 2, 'banana': 1} or {'sweet': 2, 'apple': 2, 'banana': 1}
        // Order among equal frequencies might vary, so check keys and values
        expect(topN.length, 3);
        expect(topN.containsKey('apple'), isTrue);
        expect(topN.containsKey('sweet'), isTrue);
        expect(
          topN.containsKey('banana') ||
              topN.containsKey('good') ||
              topN.containsKey('fruit'),
          isTrue,
        );
        expect(topN['apple'], 2);
        expect(topN['sweet'], 2);
      });

      test('should return top N words with custom stop words', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {
              'text_content':
                  "one one two two three three four five five five six seven seven",
            },
          ],
        );
        // Frequencies: one:2, two:2, three:2, four:1, five:3, six:1, seven:2
        // Custom stop words: ['one', 'two']
        // Filtered: three:2, four:1, five:3, six:1, seven:2
        // Top 3: five:3, three:2, seven:2 (order of three/seven might vary)
        final topN = await analysisService.getTopNWords(
          mockDatabase,
          3,
          useStopWords: true,
          customStopWords: ['one', 'two'],
        );
        expect(topN.length, 3);
        expect(topN['five'], 3);
        expect(topN.containsKey('three'), isTrue);
        expect(topN.containsKey('seven'), isTrue);
        expect(topN['three'], 2);
        expect(topN['seven'], 2);
      });

      test('should return empty map if all words are stop words', () async {
        when(mockDatabase.query('content_blocks')).thenAnswer(
          (_) async => [
            {'text_content': "the and is of"},
          ],
        );
        final topN = await analysisService.getTopNWords(
          mockDatabase,
          3,
          useStopWords: true,
          // Default stop words will cover these
        );
        expect(topN, isEmpty);
      });

      test(
        'should return fewer than N if not enough words after filtering',
        () async {
          when(mockDatabase.query('content_blocks')).thenAnswer(
            (_) async => [
              {'text_content': "apple banana the and is"},
            ],
          );
          // Filtered: apple:1, banana:1
          final topN = await analysisService.getTopNWords(
            mockDatabase,
            5, // Request 5
            useStopWords: true,
          );
          expect(topN, {'apple': 1, 'banana': 1}); // But only 2 available
        },
      );
    });
  });
}
