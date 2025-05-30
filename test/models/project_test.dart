import 'package:flutter_test/flutter_test.dart';
import 'package:lexicon/models/project.dart';

void main() {
  group('Project Model Tests', () {
    test('toMap() and fromMap() should work correctly', () {
      final now = DateTime.now();
      final originalProject = Project(
        projectId: 1, // Changed from id to projectId
        seriesId: null,
        projectName: 'Test Project',
        // projectAuthor: 'Test Author', // Removed, not in current model
        // projectDescription: 'A test project description.', // Removed
        // projectGenre: 'Testing', // Removed
        // projectTags: ['test', 'flutter'], // Removed
        sourcePath: '/path/to/source.txt',
        dbPath: '/path/to/project.db',
        wordCount: 12345,
        createdAt: now, // Changed from createdDate to createdAt
        lastImportedAt: now, // Changed from lastModifiedDate to lastImportedAt
        // projectNotes: 'Some notes about the test project.', // Removed
        // projectStatus: 'In Progress', // Removed
        // projectVersion: '1.0.0', // Removed
        // coverImage: null, // Removed
        // customFields: {'customKey': 'customValue'}, // Removed
      );

      final projectMap = originalProject.toMap();
      final projectFromMap = Project.fromMap(projectMap);

      expect(projectFromMap.projectId, originalProject.projectId);
      expect(projectFromMap.seriesId, originalProject.seriesId);
      expect(projectFromMap.projectName, originalProject.projectName);
      expect(projectFromMap.sourcePath, originalProject.sourcePath);
      expect(projectFromMap.dbPath, originalProject.dbPath);
      expect(projectFromMap.wordCount, originalProject.wordCount);
      expect(
        projectFromMap.createdAt.millisecondsSinceEpoch,
        originalProject.createdAt.millisecondsSinceEpoch,
      );
      expect(
        projectFromMap.lastImportedAt.millisecondsSinceEpoch,
        originalProject.lastImportedAt.millisecondsSinceEpoch,
      );
      // Verify that fields removed from the model are not present in the map
      expect(projectMap.containsKey('project_author'), isFalse);
      expect(projectMap.containsKey('project_description'), isFalse);
      expect(projectMap.containsKey('project_genre'), isFalse);
      expect(projectMap.containsKey('project_tags'), isFalse);
      expect(projectMap.containsKey('project_notes'), isFalse);
      expect(projectMap.containsKey('project_status'), isFalse);
      expect(projectMap.containsKey('project_version'), isFalse);
      expect(projectMap.containsKey('cover_image'), isFalse);
      expect(projectMap.containsKey('custom_fields'), isFalse);
    });

    test('copyWith should work correctly', () {
      final now = DateTime.now();
      final later = now.add(const Duration(days: 1));
      final originalProject = Project(
        projectId: 1, // Changed from id to projectId
        projectName: 'Original Name',
        // projectAuthor: 'Original Author', // Removed
        createdAt: now, // Changed from createdDate to createdAt
        lastImportedAt: now, // Changed from lastModifiedDate to lastImportedAt
        sourcePath: '/original/path',
        dbPath: '/original/db.path',
        wordCount: 100, // Added initial wordCount for clarity
      );

      final updatedProject = originalProject.copyWith(
        projectName: 'Updated Name',
        wordCount: 500,
        lastImportedAt: later,
      );

      expect(updatedProject.projectId, originalProject.projectId);
      expect(updatedProject.projectName, 'Updated Name');
      expect(updatedProject.wordCount, 500);
      expect(
        updatedProject.lastImportedAt.millisecondsSinceEpoch,
        later.millisecondsSinceEpoch,
      );
      expect(
        updatedProject.createdAt.millisecondsSinceEpoch,
        originalProject.createdAt.millisecondsSinceEpoch,
      );
      expect(updatedProject.sourcePath, originalProject.sourcePath);
      expect(updatedProject.dbPath, originalProject.dbPath);
    });
  });
}
