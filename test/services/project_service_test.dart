import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexicon/db/database_helper.dart';
import 'package:lexicon/models/project.dart';
import 'package:lexicon/models/series.dart'; // Import Series model
import 'package:lexicon/providers/database_helper_provider.dart'; // Import for masterDatabaseHelperProvider
import 'package:lexicon/services/project_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart'
    as sqflite_api; // Corrected import

// Generate mocks for DatabaseHelper and sqflite_api.Database
@GenerateMocks([DatabaseHelper, sqflite_api.Database])
import 'project_service_test.mocks.dart';

void main() {
  // Initialize FFI for sqflite if running on desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late MockDatabaseHelper mockMasterDatabaseHelper;
  late MockDatabase mockDb; // Added mock for Database
  late ProjectService projectService;
  late ProviderContainer container;

  setUp(() {
    mockMasterDatabaseHelper = MockDatabaseHelper();
    mockDb = MockDatabase(); // Initialize MockDatabase

    // When mockMasterDatabaseHelper.db is accessed, return mockDb
    when(mockMasterDatabaseHelper.db).thenReturn(mockDb);

    container = ProviderContainer(
      overrides: [
        // Ensure masterDatabaseHelperProvider is correctly referenced
        masterDatabaseHelperProvider.overrideWith(
          (ref) async => mockMasterDatabaseHelper,
        ),
      ],
    );
    // Adjust how projectService is obtained if projectServiceProvider is a FutureProvider
    // This might require awaiting the provider or adjusting the test setup
    // For simplicity, if projectServiceProvider.future is what you need:
    // projectService = await container.read(projectServiceProvider.future);
    // However, the service itself takes DatabaseHelper, not a future of it.
    // The provider setup for ProjectService might need to be synchronous if used this way in tests,
    // or the test needs to handle the async nature of the provider.

    // Assuming ProjectService can be instantiated directly for testing if provider setup is complex for unit tests:
    projectService = ProjectService(mockMasterDatabaseHelper);
    // OR, if the provider is essential:
    // container.read(projectServiceProvider); // Initialize it
    // projectService = container.read(projectServiceProvider).requireValue; // If it has resolved
  });

  tearDown(() {
    container.dispose();
  });

  group('ProjectService Tests', () {
    final now = DateTime.now();
    final testProject = Project(
      projectId: 1,
      projectName: 'Test Project',
      sourcePath: '/test/project.txt',
      dbPath: '/test/project.db',
      createdAt: now,
      lastImportedAt: now,
      wordCount: 100,
    );

    final testSeries = Series(seriesId: 1, seriesName: 'Test Series');

    test(
      'createProject should insert a project into the master database',
      () async {
        // Arrange
        final projectToInsert = testProject.copyWith(
          projectId: null,
        ); // ID is null for creation
        // The map passed to the service's insert call will include 'project_id': null
        final expectedMap = projectToInsert.toMap();

        when(
          mockDb.insert('projects', expectedMap),
        ).thenAnswer((_) async => 1); // Assuming insert returns the id

        // Act
        final createdProject = await projectService.createProject(
          projectToInsert,
        );

        // Assert
        expect(createdProject.projectId, 1);
        expect(createdProject.projectName, testProject.projectName);
        verify(mockDb.insert('projects', expectedMap)).called(1);
      },
    );

    test(
      'getAllProjects should retrieve all projects from the master database',
      () async {
        // Arrange
        when(
          mockDb.query('projects'),
        ).thenAnswer((_) async => [testProject.toMap()]);

        // Act
        final projects = await projectService.getAllProjects();

        // Assert
        expect(projects.length, 1);
        expect(projects.first.projectName, testProject.projectName);
        expect(projects.first.projectId, testProject.projectId);
        verify(mockDb.query('projects')).called(1);
      },
    );

    test('getProjectById should retrieve a specific project', () async {
      // Arrange
      when(
        mockDb.query('projects', where: 'project_id = ?', whereArgs: [1]),
      ).thenAnswer((_) async => [testProject.toMap()]);

      // Act
      final project = await projectService.getProjectById(1);

      // Assert
      expect(project, isNotNull);
      expect(project?.projectName, testProject.projectName);
      expect(project?.projectId, testProject.projectId);
      verify(
        mockDb.query('projects', where: 'project_id = ?', whereArgs: [1]),
      ).called(1);
    });

    test('updateProject should update an existing project', () async {
      // Arrange
      final updatedProject = testProject.copyWith(
        projectName: 'Updated Project Name',
        wordCount: 200,
      );
      when(
        mockDb.update(
          'projects',
          updatedProject.toMap(),
          where: 'project_id = ?',
          whereArgs: [updatedProject.projectId],
        ),
      ).thenAnswer((_) async => 1);

      // Act
      final result = await projectService.updateProject(updatedProject);

      // Assert
      expect(result, 1);
      verify(
        mockDb.update(
          'projects',
          updatedProject.toMap(),
          where: 'project_id = ?',
          whereArgs: [updatedProject.projectId],
        ),
      ).called(1);
    });

    test('deleteProject should remove a project from the database', () async {
      // Arrange
      when(
        mockDb.delete('projects', where: 'project_id = ?', whereArgs: [1]),
      ).thenAnswer((_) async => 1);

      // Act
      final result = await projectService.deleteProject(1);

      // Assert
      expect(result, 1);
      verify(
        mockDb.delete('projects', where: 'project_id = ?', whereArgs: [1]),
      ).called(1);
    });

    // --- Series Tests ---
    test(
      'createSeries should insert a series into the master database',
      () async {
        // Arrange

        when(
          mockDb.insert(
            'series',
            argThat(
              predicate<Map<String, dynamic>>((map) {
                return map['series_id'] == null &&
                    map['series_name'] == testSeries.seriesName;
              }),
            ),
          ),
        ).thenAnswer((_) async => 1);

        // Act
        final seriesId = await projectService.addSeries(testSeries.seriesName);

        // Assert
        expect(seriesId, 1);
        verify(
          mockDb.insert(
            'series',
            argThat(
              predicate<Map<String, dynamic>>((map) {
                return map['series_id'] == null &&
                    map['series_name'] == testSeries.seriesName;
              }),
            ),
          ),
        ).called(1);
      },
    );

    test('getAllSeries should retrieve all series', () async {
      // Arrange
      when(
        mockDb.query('series'),
      ).thenAnswer((_) async => [testSeries.toMap()]);

      // Act
      final seriesList = await projectService.getAllSeries();

      // Assert
      expect(seriesList.length, 1);
      expect(seriesList.first.seriesName, testSeries.seriesName);
      expect(seriesList.first.seriesId, testSeries.seriesId);
      verify(mockDb.query('series')).called(1);
    });

    test('getSeriesById should retrieve a specific series', () async {
      // Arrange
      when(
        mockDb.query('series', where: 'series_id = ?', whereArgs: [1]),
      ).thenAnswer((_) async => [testSeries.toMap()]);

      // Act
      final series = await projectService.getSeriesById(1);

      // Assert
      expect(series, isNotNull);
      expect(series?.seriesName, testSeries.seriesName);
      expect(series?.seriesId, testSeries.seriesId);
      verify(
        mockDb.query('series', where: 'series_id = ?', whereArgs: [1]),
      ).called(1);
    });

    test('updateSeries should update an existing series', () async {
      // Arrange
      final updatedSeries = testSeries.copyWith(
        seriesName: 'Updated Series Name',
      );
      when(
        mockDb.update(
          'series',
          updatedSeries.toMap(),
          where: 'series_id = ?',
          whereArgs: [updatedSeries.seriesId],
        ),
      ).thenAnswer((_) async => 1);

      // Act
      final result = await projectService.updateSeries(updatedSeries);

      // Assert
      expect(result, 1);
      verify(
        mockDb.update(
          'series',
          updatedSeries.toMap(),
          where: 'series_id = ?',
          whereArgs: [updatedSeries.seriesId],
        ),
      ).called(1);
    });

    test('deleteSeries should remove a series from the database', () async {
      // Arrange
      when(
        mockDb.delete('series', where: 'series_id = ?', whereArgs: [1]),
      ).thenAnswer((_) async => 1);

      // Act
      final result = await projectService.deleteSeries(1);

      // Assert
      expect(result, 1);
      verify(
        mockDb.delete('series', where: 'series_id = ?', whereArgs: [1]),
      ).called(1);
    });
  });
}
