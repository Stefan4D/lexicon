import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexicon/db/database_helper.dart';
import 'package:path_provider/path_provider.dart'; // For getting documents directory
import 'package:path/path.dart'; // For joining paths

import 'database_factory_provider.dart';

// Provider for the Master DatabaseHelper instance
final masterDatabaseHelperProvider = FutureProvider<DatabaseHelper>((
  ref,
) async {
  final factory = ref.watch(databaseFactoryProvider);
  final appDocsDir = await getApplicationDocumentsDirectory();
  final dbPath = join(appDocsDir.path, 'master_projects.db');

  final helper = DatabaseHelper(factory);
  await helper.init(dbPath, SchemaType.master); // Specify Master Schema
  return helper;
});

// It's often better to have a family provider or a more dynamic way to get project-specific DB helpers
// For now, this is a placeholder to illustrate the concept.
// You might have a provider that takes a projectId and returns its DatabaseHelper.
final projectDatabaseHelperProvider = FutureProvider.family<
  DatabaseHelper,
  String
>((ref, projectDbPath) async {
  final factory = ref.watch(databaseFactoryProvider);
  // projectDbPath would be retrieved from the master DB for a specific project
  final helper = DatabaseHelper(factory);
  await helper.init(
    projectDbPath,
    SchemaType.project,
  ); // Specify Project Schema
  return helper;
});

// The old generic provider might be removed or refactored
// final databaseHelperProvider = FutureProvider<DatabaseHelper>((ref) async {
//   final factory = ref.watch(databaseFactoryProvider);
//   // This would need a default path and schema type, or be more specific
//   final helper = DatabaseHelper(factory);
//   // await helper.init('some_default.db', SchemaType.project); // Example
//   return helper;
// });
