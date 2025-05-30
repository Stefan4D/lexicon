import 'package:flutter/foundation.dart'; // Added for listEquals
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexicon/models/project.dart';
import 'package:lexicon/services/project_service.dart';
import 'package:lexicon/main.dart'; // For detailPageProvider
import 'package:lexicon/services/analysis_service.dart';
import 'package:lexicon/providers/database_helper_provider.dart'; // Corrected import
import 'package:lexicon/db/database_helper.dart';
import 'package:sqflite_common/sqlite_api.dart'; // For Database type
import 'package:sqflite/sqflite.dart' as sqflite; // Import for firstIntValue
import 'package:lexicon/screens/settings_screen.dart';
import 'package:flutter/services.dart';

// Parameter class for topNWordsProvider
class TopNWordsParams {
  final int topN;
  final bool useStopWords;
  final List<String> stopWords;

  TopNWordsParams({
    required this.topN,
    required this.useStopWords,
    required this.stopWords,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopNWordsParams &&
          runtimeType == other.runtimeType &&
          topN == other.topN &&
          useStopWords == other.useStopWords &&
          listEquals(stopWords, other.stopWords);

  @override
  int get hashCode => Object.hash(topN, useStopWords, stopWords);
}

// State provider for the current project being viewed/edited on this screen
final _currentProjectProvider = StateProvider<Project?>((ref) => null);

// Provider for top N words
final topNWordsProvider = FutureProvider.autoDispose.family<
  Map<String, int>,
  TopNWordsParams
>((ref, params) async {
  final analysisService = ref.watch(analysisServiceProvider);
  final currentProject = ref.watch(_currentProjectProvider);

  if (currentProject == null || currentProject.projectId == null) {
    print(
      '[TopNWordsProvider] No current project or project ID, returning empty.',
    );
    return {};
  }

  // Use the dbPath from the project model directly
  final String? projectDbPath = currentProject.dbPath;

  if (projectDbPath == null || projectDbPath.isEmpty) {
    print(
      '[TopNWordsProvider] Error: project.dbPath is null or empty. Project ID: ${currentProject.projectId}',
    );
    // Potentially throw an error or return an empty map depending on desired behavior
    // For now, returning empty to avoid crashing, but this indicates a problem upstream.
    return {};
  }
  print('[TopNWordsProvider] Using Project DB Path from model: $projectDbPath');

  try {
    // 1. Get the DatabaseHelper for the project-specific database
    final DatabaseHelper projectDbHelper = await ref.watch(
      projectDatabaseHelperProvider(projectDbPath).future,
    );
    print(
      '[TopNWordsProvider] Obtained projectDbHelper for path: $projectDbPath',
    );

    // 2. Get the actual Database object from the helper
    final Database? projectSpecificDb = projectDbHelper.db;

    if (projectSpecificDb == null) {
      print(
        '[TopNWordsProvider] Error: projectSpecificDb is null after obtaining helper for path: $projectDbPath',
      );
      return {}; // Or throw an error
    }
    print(
      '[TopNWordsProvider] Obtained projectSpecificDb instance for path: $projectDbPath',
    );

    final words = await analysisService.getTopNWords(
      projectSpecificDb,
      params.topN,
      useStopWords: params.useStopWords,
      customStopWords: params.stopWords,
    );
    print(
      '[TopNWordsProvider] Got ${words.length} words from path: $projectDbPath',
    );
    return words;
  } catch (e, stackTrace) {
    print(
      '[TopNWordsProvider] Error fetching top N words for path $projectDbPath: $e\n$stackTrace',
    );
    rethrow;
  }
});

// Provider to manage the state of the stop words switch
final _useStopWordsSwitchProvider = StateProvider<bool>((ref) => false);

// Provider for chapter count
final chapterCountProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  projectDbPath,
) async {
  if (projectDbPath.isEmpty) return 0;
  final dbHelper = await ref.watch(
    projectDatabaseHelperProvider(projectDbPath).future,
  );
  final db = dbHelper.db;
  if (db == null) return 0;
  final result = await db.rawQuery('SELECT COUNT(*) as count FROM chapters');
  return sqflite.Sqflite.firstIntValue(result) ?? 0; // Corrected usage
});

// Provider for scene count
final sceneCountProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  projectDbPath,
) async {
  if (projectDbPath.isEmpty) return 0;
  final dbHelper = await ref.watch(
    projectDatabaseHelperProvider(projectDbPath).future,
  );
  final db = dbHelper.db;
  if (db == null) return 0;
  final result = await db.rawQuery('SELECT COUNT(*) as count FROM scenes');
  return sqflite.Sqflite.firstIntValue(result) ?? 0; // Corrected usage
});

// Provider for content block count
final contentBlockCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, projectDbPath) async {
      if (projectDbPath.isEmpty) return 0;
      final dbHelper = await ref.watch(
        projectDatabaseHelperProvider(projectDbPath).future,
      );
      final db = dbHelper.db;
      if (db == null) return 0;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM content_blocks',
      );
      return sqflite.Sqflite.firstIntValue(result) ?? 0; // Corrected usage
    });

class ProjectScreen extends ConsumerStatefulWidget {
  final Project initialProject;

  const ProjectScreen({super.key, required this.initialProject});

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  late TextEditingController _projectNameController;
  bool _isEditingProjectName = false;
  final FocusNode _projectNameFocusNode = FocusNode();
  ScrollController? _scrollController; // Changed to nullable

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // Initialization remains
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(_currentProjectProvider.notifier).state =
            widget.initialProject;
      }
    });
    _projectNameController = TextEditingController(
      text: widget.initialProject.projectName,
    );
  }

  @override
  void didUpdateWidget(covariant ProjectScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialProject != oldWidget.initialProject) {
      ref.read(_currentProjectProvider.notifier).state = widget.initialProject;
      _projectNameController.text = widget.initialProject.projectName;
      if (_isEditingProjectName) {
        setState(() {
          _isEditingProjectName = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectNameFocusNode.dispose();
    _scrollController?.dispose(); // Dispose with null check
    super.dispose();
  }

  Future<void> _deleteProject(BuildContext context, WidgetRef ref) async {
    final project = ref.read(_currentProjectProvider);
    if (project == null || project.projectId == null) return;

    final projectService = await ref.read(projectServiceProvider.future);
    try {
      await projectService.deleteProject(project.projectId!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project \"${project.projectName}\" deleted.'),
          ),
        );
        ref.read(detailPageProvider.notifier).state = null;
        ref.invalidate(projectServiceProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting project: $e')));
      }
    }
  }

  Future<void> _saveProjectName() async {
    final project = ref.read(_currentProjectProvider);
    if (project == null || project.projectId == null) return;

    final newName = _projectNameController.text.trim();
    if (newName.isEmpty || newName == project.projectName) {
      setState(() {
        _isEditingProjectName = false;
        _projectNameController.text = project.projectName;
      });
      return;
    }

    final projectService = await ref.read(projectServiceProvider.future);
    try {
      final updatedProject = await projectService.updateProjectName(
        project.projectId!,
        newName,
      );
      if (updatedProject != null) {
        ref.read(_currentProjectProvider.notifier).state = updatedProject;
        setState(() {
          _isEditingProjectName = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project name updated.')),
          );
        }
        ref.invalidate(projectServiceProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating project name: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final currentProject = ref.watch(_currentProjectProvider);

    if (currentProject == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.primaryContainer,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(detailPageProvider.notifier).state = null;
          },
        ),
        title: Text(
          _isEditingProjectName
              ? 'Edit Project Name'
              : currentProject.projectName,
        ),
        backgroundColor: theme.colorScheme.surfaceContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Project',
            onPressed: () async {
              final confirmDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Delete Project?'),
                    content: Text(
                      'Are you sure you want to delete \"${currentProject.projectName}\"? This action cannot be undone.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                      ),
                      TextButton(
                        child: Text(
                          'Delete',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                      ),
                    ],
                  );
                },
              );

              if (confirmDelete == true) {
                await _deleteProject(context, ref);
              }
            },
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.primaryContainer,
      body: ListView(
        controller:
            _scrollController, // Remains as is, ListView handles nullable controller
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildProjectHeader(context, theme, textTheme, currentProject),
          const SizedBox(height: 24),
          _buildStatsCard(context, theme, textTheme, currentProject),
          const SizedBox(height: 24),
          _buildWordFrequencyCard(context, theme, textTheme, currentProject),
          const SizedBox(height: 24),
          _buildContentOverviewCard(context, textTheme, currentProject),
        ],
      ),
    );
  }

  Widget _buildProjectHeader(
    BuildContext context,
    ThemeData theme,
    TextTheme textTheme,
    Project project,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child:
                  _isEditingProjectName
                      ? RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (RawKeyEvent event) {
                          if (event is RawKeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.escape) {
                            setState(() {
                              _isEditingProjectName = false;
                              _projectNameController.text = project.projectName;
                              _projectNameFocusNode.unfocus();
                            });
                          }
                        },
                        child: TextField(
                          controller: _projectNameController,
                          focusNode: _projectNameFocusNode,
                          autofocus: true,
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter project name',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _saveProjectName(),
                        ),
                      )
                      : Text(
                        project.projectName,
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
            ),
            if (_isEditingProjectName) ...[
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                tooltip: 'Save Name',
                onPressed: _saveProjectName,
              ),
              IconButton(
                icon: Icon(
                  Icons.cancel_outlined,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Cancel Edit',
                onPressed: () {
                  setState(() {
                    _isEditingProjectName = false;
                    _projectNameController.text = project.projectName;
                  });
                },
              ),
            ] else
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: theme.colorScheme.secondary,
                ),
                tooltip: 'Edit Name',
                onPressed: () {
                  setState(() {
                    _isEditingProjectName = true;
                    // Ensure the text field gets focus when edit mode starts
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _projectNameFocusNode.requestFocus();
                    });
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          project.sourcePath,
          style: textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    ThemeData theme,
    TextTheme textTheme,
    Project project,
  ) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Statistics',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              context,
              theme: theme,
              icon: Icons.bar_chart,
              label: 'Word Count',
              value: project.wordCount.toString(),
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              context,
              theme: theme,
              icon: Icons.edit_calendar_outlined,
              label: 'Last Imported',
              value: project.lastImportedAt.toLocal().toString().split(' ')[0],
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              context,
              theme: theme,
              icon: Icons.create_new_folder_outlined,
              label: 'Created Date',
              value: project.createdAt.toLocal().toString().split(' ')[0],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordFrequencyCard(
    BuildContext context,
    ThemeData theme,
    TextTheme textTheme,
    Project project,
  ) {
    final currentStopWords = ref.watch(stopWordsProvider);
    final bool useStopWords = ref.watch(_useStopWordsSwitchProvider);

    final params = TopNWordsParams(
      topN: 10,
      useStopWords: useStopWords,
      stopWords: currentStopWords,
    );

    final topNWordsValue = ref.watch(topNWordsProvider(params));

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top 10 Word Frequencies',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('Use Stop Words'),
              value: useStopWords,
              onChanged: (bool value) {
                final scrollCtrl =
                    _scrollController; // Capture to local variable
                if (scrollCtrl == null) return; // Guard against null controller

                // Save current scroll offset before triggering rebuild
                final currentOffset =
                    scrollCtrl.hasClients ? scrollCtrl.offset : 0.0;
                ref.read(_useStopWordsSwitchProvider.notifier).state = value;
                // After the state is updated and UI rebuilds, restore scroll position
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollCtrl.hasClients) {
                    scrollCtrl.jumpTo(currentOffset);
                  }
                });
              },
              secondary: const Icon(Icons.filter_list),
            ),
            const Divider(),
            topNWordsValue.when(
              data: (words) {
                if (words.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 16.0,
                    ), // Adjusted padding
                    child: Center(child: Text('No word data available.')),
                  );
                }
                // Sort entries by frequency in descending order
                final sortedEntries =
                    words.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                return Padding(
                  padding: const EdgeInsets.only(
                    top: 16.0,
                  ), // Add padding to the top of the list
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch, // Make children take full width
                    children:
                        sortedEntries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 16.0,
                            ), // Padding for each item
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  // Allow word to take available space and wrap if needed
                                  child: Text(
                                    entry.key,
                                    style:
                                        theme
                                            .textTheme
                                            .titleMedium, // Changed from bodyMedium
                                    overflow:
                                        TextOverflow
                                            .ellipsis, // Handle long words
                                  ),
                                ),
                                Text(
                                  entry.value.toString(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    // Changed from bodyMedium
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
              },
              loading: () {
                return const Center(child: CircularProgressIndicator());
              },
              error: (error, stackTrace) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('Error loading word frequencies: $error'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentOverviewCard(
    BuildContext context,
    TextTheme textTheme,
    Project project,
  ) {
    final theme = Theme.of(context); // Get theme for icons and styles
    final projectDbPath = project.dbPath;

    // Watch the providers. projectDbPath is asserted non-null by type system.
    final chapters = ref.watch(chapterCountProvider(projectDbPath));
    final scenes = ref.watch(sceneCountProvider(projectDbPath));
    final contentBlocks = ref.watch(contentBlockCountProvider(projectDbPath));

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Overview',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            _buildStatItem(
              context,
              theme: theme,
              icon: Icons.menu_book_outlined, // Chapter icon
              label: 'Chapters',
              value: chapters.when(
                data: (count) => count.toString(),
                loading: () => '...',
                error: (e, s) => 'Error',
              ),
            ),
            const Divider(height: 24, thickness: 1), // Added Divider
            _buildStatItem(
              context,
              theme: theme,
              icon: Icons.movie_creation_outlined, // Scene icon
              label: 'Scenes',
              value: scenes.when(
                data: (count) => count.toString(),
                loading: () => '...',
                error: (e, s) => 'Error',
              ),
            ),
            const Divider(height: 24, thickness: 1), // Added Divider
            _buildStatItem(
              context,
              theme: theme,
              icon: Icons.article_outlined, // Content Block icon
              label: 'Content Blocks',
              value: contentBlocks.when(
                data: (count) => count.toString(),
                loading: () => '...',
                error: (e, s) => 'Error',
              ),
            ),
            const Divider(
              height: 32,
              thickness: 1,
            ), // Added Divider before button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Manuscript'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'View Manuscript feature not implemented yet.',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required ThemeData theme, // Added theme
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, color: theme.colorScheme.secondary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
