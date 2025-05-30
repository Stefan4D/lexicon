import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexicon/models/project.dart';
import 'package:lexicon/providers/database_helper_provider.dart';
import 'package:lexicon/services/file_parser_service.dart'; // Added import
import 'package:lexicon/services/project_service.dart';
import 'package:lexicon/utils/file_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // For path manipulation
import 'dart:io'; // For Directory
import 'package:sqflite_common/sqlite_api.dart'
    as sqflite_api; // For Database type

// Updated Provider for the ProjectImportService to be a FutureProvider
final projectImportServiceProvider = FutureProvider<ProjectImportService>((
  ref,
) async {
  // Await the ProjectService instance
  final projectService = await ref.watch(projectServiceProvider.future);
  return ProjectImportService(ref, projectService);
});

class ProjectImportService {
  final Ref _ref;
  final ProjectService _projectService; // To add project to master DB

  ProjectImportService(this._ref, this._projectService);

  Future<Project?> importProject(
    PickedFileResult pickedFile, {
    String? customProjectName,
  }) async {
    try {
      // 1. Determine Project Name
      final projectName =
          customProjectName ?? p.basenameWithoutExtension(pickedFile.name);

      // 2. Create Project-Specific Database Path
      final appDocsDir = await getApplicationDocumentsDirectory();
      final sanitizedProjectNameForFileName = projectName.replaceAll(
        RegExp(
          r'[^a-zA-Z0-9_\\-]', // Corrected: Replace characters not alphanumeric, underscore, or hyphen
        ),
        '_',
      );
      // Corrected: Removed unnecessary braces for sanitizedProjectNameForFileName
      final projectDbFileName = '$sanitizedProjectNameForFileName.db';
      final projectDbPath = p.join(
        appDocsDir.path,
        'project_databases',
        projectDbFileName,
      );

      // Ensure the directory for project databases exists
      final projectDbDir = Directory(
        p.join(appDocsDir.path, 'project_databases'),
      );
      if (!await projectDbDir.exists()) {
        await projectDbDir.create(recursive: true);
      }

      // 3. Create initial Project object and add to Master Database
      final now = DateTime.now();
      final initialProjectData = Project(
        projectName: projectName,
        sourcePath: pickedFile.path, // Store the original source file path
        dbPath: projectDbPath,
        createdAt: now, // Corrected: was createdDate
        lastImportedAt: now, // Corrected: was lastModifiedDate
        wordCount: 0, // Now a valid field, defaults to 0 in Project model too
      );

      // Use createProject which returns the created project with its ID
      final createdProjectInMasterDb = await _projectService.createProject(
        initialProjectData,
      );
      if (createdProjectInMasterDb.projectId == null) {
        // Corrected: was .id
        throw Exception(
          'Failed to create project in master database or obtain ID.',
        );
      }

      // 4. Initialize Project-Specific Database
      final projectDbHelper = await _ref.read(
        projectDatabaseHelperProvider(projectDbPath).future,
      );
      if (projectDbHelper.db == null) {
        throw Exception('Project database failed to initialize.');
      }
      final sqflite_api.Database projectSqfliteDb = projectDbHelper.db!;

      // 5. Parse the file and populate the project database
      final fileParser = _ref.read(fileParserServiceProvider);
      final File fileToParse = File(pickedFile.path);
      final parsingResult = await fileParser.parseFile(
        fileToParse, // Pass the File object
        projectSqfliteDb, // Pass the sqflite_api.Database instance
        createdProjectInMasterDb.projectId!,
      );

      final int wordCount = parsingResult['wordCount'] as int? ?? 0;

      // 6. Update the project in the master database with the word count
      final updatedProjectData = createdProjectInMasterDb.copyWith(
        wordCount: wordCount, // Assign the extracted word count
        lastImportedAt: DateTime.now(),
      );
      await _projectService.updateProject(updatedProjectData);

      print(
        'Project "${updatedProjectData.projectName}" (ID: ${updatedProjectData.projectId}) imported and parsed. Word count: $wordCount', // Corrected: was .id
      );

      // 7. Return the updated project details
      return updatedProjectData;
    } catch (e) {
      print('Error during project import: $e');
      return null;
    }
  }
}
