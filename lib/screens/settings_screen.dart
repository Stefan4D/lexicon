import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexicon/constants/default_stop_words.dart';

// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

// Provider for the stop words list
final stopWordsProvider =
    StateNotifierProvider<StopWordsNotifier, List<String>>((ref) {
      final sharedPrefs = ref.watch(sharedPreferencesProvider);
      return sharedPrefs.when(
        data: (prefs) => StopWordsNotifier(prefs),
        loading: () => StopWordsNotifier(null), // Initial state while loading
        error: (_, __) => StopWordsNotifier(null), // Error state
      );
    });

class StopWordsNotifier extends StateNotifier<List<String>> {
  final SharedPreferences? _prefs;
  static const stopWordsKey =
      'custom_stop_words'; // Made public for test access

  StopWordsNotifier(this._prefs) : super(defaultStopWords.toList()) {
    // Ensure it's a List
    _loadStopWords();
  }

  Future<void> _loadStopWords() async {
    if (_prefs == null) {
      state = defaultStopWords.toList(); // Fallback if prefs not available
      return;
    }
    final customStopWords = _prefs!.getStringList(stopWordsKey);
    if (customStopWords != null) {
      state = customStopWords;
    } else {
      state = defaultStopWords.toList(); // Initialize with default if not set
    }
  }

  Future<void> updateStopWords(List<String> newStopWords) async {
    state = newStopWords;
    if (_prefs != null) {
      await _prefs!.setStringList(stopWordsKey, newStopWords);
    }
  }

  Future<void> resetToDefault() async {
    state = defaultStopWords.toList();
    if (_prefs != null) {
      await _prefs!.setStringList(stopWordsKey, defaultStopWords.toList());
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopWords = ref.watch(stopWordsProvider);
    final stopWordsNotifier = ref.read(stopWordsProvider.notifier);
    final TextEditingController stopWordsController = TextEditingController(
      text: stopWords.join('\n'),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Text(
              'Stop Words',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Define a list of words to be excluded from frequency analysis. '
              'Enter one word per line.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stopWordsController,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter stop words here, one per line...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await stopWordsNotifier.resetToDefault();
                    stopWordsController.text = defaultStopWords.join('\n');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stop words reset to default.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Reset to Default'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final newStopWords =
                        stopWordsController.text
                            .split('\n')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                    await stopWordsNotifier.updateStopWords(newStopWords);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stop words updated.')),
                      );
                    }
                  },
                  child: const Text('Save Stop Words'),
                ),
              ],
            ),
            const Divider(height: 32),
            // Add more settings sections here in the future
          ],
        ),
      ),
    );
  }
}
