import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexicon/models/project.dart';
import 'package:lexicon/screens/project_screen.dart'; // For TopNNGramsParams
import 'package:lexicon/providers/database_helper_provider.dart'; // For projectDatabaseHelperProvider
import 'package:lexicon/db/database_helper.dart'; // For DatabaseHelper
import 'package:lexicon/services/analysis_service.dart'; // For analysisServiceProvider
import 'package:sqflite_common/sqlite_api.dart'; // For Database type

// Provider for the custom n value input
final customNValueProvider = StateProvider<int>(
  (ref) => 3,
); // Default to 3 for initial view

// Provider for the results of the custom n-gram search
// It will hold AsyncValue to represent loading/data/error states.
final customNGramResultsProvider = StateProvider<AsyncValue<Map<String, int>>?>(
  (ref) => null,
);

// A family provider to fetch n-grams, dependent on project and n-gram parameters.
// This is distinct from topNNGramsProvider in project_screen.dart because
// it doesn't rely on _currentProjectProvider, instead taking project details directly.
final nGramAnalysisDataProvider = FutureProvider.autoDispose.family<
  Map<String, int>,
  ({Project project, TopNNGramsParams params})
>((ref, args) async {
  final analysisService = ref.watch(analysisServiceProvider);
  final projectDbPath = args.project.dbPath;

  try {
    final DatabaseHelper projectDbHelper = await ref.watch(
      projectDatabaseHelperProvider(projectDbPath).future,
    );
    final Database? projectSpecificDb = projectDbHelper.db;

    if (projectSpecificDb == null) {
      print(
        '[nGramAnalysisDataProvider] Error: projectSpecificDb is null for path: $projectDbPath',
      );
      return {};
    }

    final nGrams = await analysisService.getTopNNGrams(
      projectSpecificDb,
      args.params.nValueForNGram,
      args.params.topNCount,
    );
    return nGrams;
  } catch (e, stackTrace) {
    print(
      '[nGramAnalysisDataProvider] Error fetching top N ${args.params.nValueForNGram}-grams for path $projectDbPath: $e\\n$stackTrace',
    );
    rethrow;
  }
});

class NGramAnalysisScreen extends ConsumerStatefulWidget {
  final Project project;

  const NGramAnalysisScreen({super.key, required this.project});

  @override
  ConsumerState<NGramAnalysisScreen> createState() =>
      _NGramAnalysisScreenState();
}

class _NGramAnalysisScreenState extends ConsumerState<NGramAnalysisScreen> {
  final TextEditingController _customNController = TextEditingController();
  bool _isLoadingCustom = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Reset providers when the screen is initialized for a new project instance
    // This handles cases where the screen might be reused without full disposal/recreation
    // if Flutter's widget tree optimization keeps the state alive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(customNValueProvider.notifier).state = 3; // Reset to default
        ref.read(customNGramResultsProvider.notifier).state =
            null; // Clear results
        _customNController.clear(); // Clear the text field
      }
    });
  }

  @override
  void dispose() {
    _customNController.dispose();
    _scrollController.dispose(); // Dispose the ScrollController
    // It's also good practice to reset providers on dispose, though initState handles the fresh state.
    // This ensures that if the provider is accessed by something else after dispose (less likely for StateProvider),
    // it's in a clean state.
    // However, for simple StateProviders like these, resetting in initState when the widget is built for a new project
    // is often sufficient. If they were .autoDispose, Riverpod would handle it.
    // For now, let's rely on the initState reset for a clean slate per project view.
    super.dispose();
  }

  Future<void> _fetchCustomNGrams() async {
    final nText = _customNController.text.trim();
    if (nText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a value for n.')),
      );
      return;
    }
    final n = int.tryParse(nText);
    if (n == null || n < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive number for n.'),
        ),
      );
      return;
    }

    ref.read(customNValueProvider.notifier).state = n;
    setState(() {
      _isLoadingCustom = true;
      // Clear previous custom results immediately and show loading
      ref.read(customNGramResultsProvider.notifier).state =
          const AsyncValue.loading();
    });

    try {
      final params = TopNNGramsParams(nValueForNGram: n, topNCount: 5);
      // Use the new nGramAnalysisDataProvider
      final result = await ref.read(
        nGramAnalysisDataProvider((
          project: widget.project,
          params: params,
        )).future,
      );
      ref.read(customNGramResultsProvider.notifier).state = AsyncValue.data(
        result,
      );

      // Scroll to the results card after data is fetched and state is updated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _resultsCardKey.currentContext != null) {
          Scrollable.ensureVisible(
            _resultsCardKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.5, // Attempt to center the card in the viewport
          );
        }
      });
    } catch (e, s) {
      ref.read(customNGramResultsProvider.notifier).state = AsyncValue.error(
        e,
        s,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCustom = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer, // Add this line
      appBar: AppBar(
        title: Text('N-gram Analysis - ${widget.project.projectName}'),
        backgroundColor: theme.colorScheme.surfaceContainer,
      ),
      body: ListView(
        controller: _scrollController, // Assign the ScrollController
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNGramSection(
            context,
            theme,
            textTheme,
            3,
            'Top 5 Trigrams (n=3)',
          ),
          const SizedBox(height: 24),
          _buildNGramSection(
            context,
            theme,
            textTheme,
            4,
            'Top 5 Quadgrams (n=4)',
          ),
          const SizedBox(height: 24),
          _buildNGramSection(
            context,
            theme,
            textTheme,
            5,
            'Top 5 Quintgrams (n=5)',
          ),
          const SizedBox(height: 24),
          _buildCustomNGramInput(context, theme, textTheme),
          const SizedBox(height: 16),
          _buildCustomNGramResults(context, theme, textTheme),
          // Add extra scrollable space at the bottom
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        ],
      ),
    );
  }

  Widget _buildNGramSection(
    BuildContext context,
    ThemeData theme,
    TextTheme textTheme,
    int n,
    String title,
  ) {
    final nGramParams = TopNNGramsParams(nValueForNGram: n, topNCount: 5);
    // Use the new nGramAnalysisDataProvider, passing the project and params
    final topNGramsValue = ref.watch(
      nGramAnalysisDataProvider((project: widget.project, params: nGramParams)),
    );

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            topNGramsValue.when(
              data: (nGrams) {
                if (nGrams.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('No ${n}-gram data available.')),
                  );
                }
                final sortedEntries =
                    nGrams.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                return _buildNGramList(sortedEntries, theme);
              },
              loading:
                  () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('Error loading ${n}-grams: $error'),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNGramInput(
    BuildContext context,
    ThemeData theme,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify N-gram Length', // Changed title
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customNController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ], // Add this line
              decoration: InputDecoration(
                labelText: 'Enter n value (e.g., 2 for bigrams)',
                hintText: 'E.g., 2 or 3',
                border: const OutlineInputBorder(),
                suffixIcon:
                    _isLoadingCustom
                        ? const Padding(
                          padding: EdgeInsets.all(10.0), // Adjusted padding
                          child: SizedBox(
                            width: 20, // Constrain size
                            height: 20, // Constrain size
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                        : IconButton(
                          icon: const Icon(Icons.send), // Changed icon
                          tooltip: 'Apply N Value', // Changed tooltip
                          onPressed: _fetchCustomNGrams,
                        ),
              ),
              onSubmitted: (_) => _fetchCustomNGrams(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNGramResults(
    BuildContext context,
    ThemeData theme,
    TextTheme textTheme,
  ) {
    final customResultsAsyncValue = ref.watch(customNGramResultsProvider);
    final customN = ref.watch(customNValueProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0, // Align to the top during animation
            child: child,
          ),
        );
      },
      child:
          customResultsAsyncValue == null
              ? const SizedBox.shrink() // Don't show anything if no search has been performed
              : Padding(
                // Wrap Card with Padding
                padding: const EdgeInsets.only(top: 8.0), // Apply margin here
                child: Card(
                  key: _resultsCardKey, // Assign the GlobalKey
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  // margin: const EdgeInsets.only(top: 8.0), // Removed from here
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top 5 ${customN}-grams',
                          style: textTheme.titleLarge?.copyWith(
                            // Changed to titleLarge
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        customResultsAsyncValue.when(
                          data: (nGrams) {
                            if (nGrams.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                child: Center(
                                  child: Text(
                                    'No ${customN}-gram data found for n=$customN.',
                                  ),
                                ),
                              );
                            }
                            final sortedEntries =
                                nGrams.entries.toList()
                                  ..sort((a, b) => b.value.compareTo(a.value));
                            return _buildNGramList(sortedEntries, theme);
                          },
                          loading:
                              () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          error:
                              (error, stackTrace) => Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    'Error loading custom ${customN}-grams: $error',
                                  ),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildNGramList(
    List<MapEntry<String, int>> sortedNGrams,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            sortedNGrams.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
