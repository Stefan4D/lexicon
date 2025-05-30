import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexicon/constants/default_stop_words.dart';
import 'package:lexicon/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock SharedPreferences
class MockSharedPreferences implements SharedPreferences {
  final Map<String, Object> _values = {};

  @override
  Future<bool> clear() {
    _values.clear();
    return Future.value(true);
  }

  @override
  Future<bool> commit() => Future.value(true);

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  Object? get(String key) => _values[key];

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  double? getDouble(String key) => _values[key] as double?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  Set<String> getKeys() => _values.keys.toSet();

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  List<String>? getStringList(String key) => _values[key] as List<String>?;

  @override
  Future<void> reload() => Future.value();

  @override
  Future<bool> remove(String key) async {
    _values.remove(key);
    return Future.value(true);
  }

  @override
  Future<bool> setBool(String key, bool value) {
    _values[key] = value;
    return Future.value(true);
  }

  @override
  Future<bool> setDouble(String key, double value) {
    _values[key] = value;
    return Future.value(true);
  }

  @override
  Future<bool> setInt(String key, int value) {
    _values[key] = value;
    return Future.value(true);
  }

  @override
  Future<bool> setString(String key, String value) {
    _values[key] = value;
    return Future.value(true);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) {
    _values[key] = value;
    return Future.value(true);
  }
}

void main() {
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWith(
          (ref) => Future.value(mockSharedPreferences),
        ),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  group('SettingsScreen Tests', () {
    testWidgets('loads default stop words initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(); // Wait for async operations

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      expect(
        (tester.widget(textField) as TextField).controller!.text,
        defaultStopWords.join('\n'),
      );
    });

    testWidgets('loads custom stop words if previously saved', (
      WidgetTester tester,
    ) async {
      final customWords = ['custom1', 'custom2'];
      await mockSharedPreferences.setStringList(
        StopWordsNotifier.stopWordsKey,
        customWords,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      expect(
        (tester.widget(textField) as TextField).controller!.text,
        customWords.join('\n'),
      );
    });

    testWidgets('saves new stop words', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'new1\nnew2');
      await tester.tap(find.text('Save Stop Words'));
      await tester.pumpAndSettle();

      // Verify SharedPreferences was updated
      expect(
        mockSharedPreferences.getStringList(StopWordsNotifier.stopWordsKey),
        ['new1', 'new2'],
      );

      // Verify UI reflects the change (though it might require re-reading provider)
      // For simplicity, we check SharedPreferences directly.
      // To check UI, one might need to re-pump or ensure provider updates propagate.
    });

    testWidgets('resets stop words to default', (WidgetTester tester) async {
      // First, set some custom words
      final customWords = ['custom1', 'custom2'];
      await mockSharedPreferences.setStringList(
        StopWordsNotifier.stopWordsKey,
        customWords,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ensure custom words are loaded
      final textField = find.byType(TextField);
      expect(
        (tester.widget(textField) as TextField).controller!.text,
        customWords.join('\n'),
      );

      // Tap reset button
      await tester.tap(find.text('Reset to Default'));
      await tester.pumpAndSettle();

      // Verify SharedPreferences was updated to default
      expect(
        mockSharedPreferences.getStringList(StopWordsNotifier.stopWordsKey),
        defaultStopWords.toList(), // Corrected: Compare List with List
      );

      // Verify TextField is updated
      expect(
        (tester.widget(textField) as TextField).controller!.text,
        defaultStopWords.join('\n'),
      );
    });

    testWidgets('Save button updates SharedPreferences and shows SnackBar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final inputWords = 'word1\nword2\nword3';
      await tester.enterText(find.byType(TextField), inputWords);
      await tester.tap(find.text('Save Stop Words'));
      await tester.pump(); // Pump once for SnackBar to appear

      expect(
        mockSharedPreferences.getStringList(StopWordsNotifier.stopWordsKey),
        ['word1', 'word2', 'word3'],
      );
      expect(find.text('Stop words updated.'), findsOneWidget);

      await tester.pumpAndSettle(); // Settle SnackBar
    });

    testWidgets(
      'Reset button updates SharedPreferences, TextField, and shows SnackBar',
      (WidgetTester tester) async {
        // Set initial custom words
        await mockSharedPreferences.setStringList(
          StopWordsNotifier.stopWordsKey,
          ['custom', 'words'],
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reset to Default'));
        await tester.pump(); // Pump once for SnackBar to appear

        expect(
          mockSharedPreferences.getStringList(StopWordsNotifier.stopWordsKey),
          defaultStopWords.toList(), // Corrected: Compare List with List
        );
        expect(
          (tester.widget(find.byType(TextField)) as TextField).controller!.text,
          defaultStopWords.join('\n'),
        );
        expect(find.text('Stop words reset to default.'), findsOneWidget);

        await tester.pumpAndSettle(); // Settle SnackBar
      },
    );
  });
}
