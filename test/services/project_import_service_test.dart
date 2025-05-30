import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexicon/db/database_helper.dart';
import 'package:lexicon/models/project.dart';
import 'package:lexicon/providers/database_helper_provider.dart';
import 'package:lexicon/services/project_import_service.dart';
import 'package:lexicon/services/project_service.dart';
import 'package:lexicon/services/file_parser_service.dart';
import 'package:lexicon/utils/file_utils.dart'; // Keep for PickedFileResult
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite_api;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

// Generate mocks
@GenerateMocks([
  DatabaseHelper,
  ProjectService,
  FileParserService,
  sqflite_api.Database, // Mock for the sqflite Database object
])
import 'project_import_service_test.mocks.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String applicationDocumentsPathToReturn;
  // Other paths remain hardcoded as they are not part of the current issue.
  // They could be made dynamic similarly if needed in the future.

  MockPathProviderPlatform({required this.applicationDocumentsPathToReturn});

  @override
  Future<String?> getTemporaryPath() async => '/tmp';
  @override
  Future<String?> getApplicationSupportPath() async => '/appsupport';
  @override
  Future<String?> getLibraryPath() async => '/library';
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      applicationDocumentsPathToReturn;
  @override
  Future<String?> getExternalStoragePath() async => '/external';
  @override
  Future<List<String>?> getExternalCachePaths() async => ['/extcache'];
  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => ['/extstorage'];
  @override
  Future<String?> getDownloadsPath() async => '/downloads';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Add this line
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late MockDatabaseHelper mockMasterDbHelper;
  late MockProjectService mockProjectService;
  late MockFileParserService mockFileParserService;
  late MockDatabase mockSqfliteDatabase; // Renamed for clarity
  late ProviderContainer
  container; // Will be initialized within each test or group
  late String mockAppDocumentsPath;
  late Directory
  tempTestDir; // For creating temporary files for PickedFileResult

  setUpAll(() async {
    mockAppDocumentsPath = p.join(Directory.current.path, 'test_documents');
    Directory(mockAppDocumentsPath).createSync(recursive: true);

    final mockPathProvider = MockPathProviderPlatform(
      applicationDocumentsPathToReturn: mockAppDocumentsPath,
    );
    PathProviderPlatform.instance = mockPathProvider;
    // The previous 'when(mockPathProvider.getApplicationDocumentsPath()).thenAnswer(...)'
    // was incorrect as MockPathProviderPlatform is not a mockito mock.
    // The behavior is now directly implemented in the fake class.
  });

  tearDownAll(() {
    Directory(mockAppDocumentsPath).deleteSync(recursive: true);
  });

  setUp(() async {
    mockMasterDbHelper = MockDatabaseHelper();
    mockProjectService = MockProjectService();
    mockFileParserService = MockFileParserService();
    mockSqfliteDatabase = MockDatabase();

    when(mockMasterDbHelper.db).thenReturn(mockSqfliteDatabase);

    // Create a general temp directory for files whose paths might be used in PickedFileResult
    tempTestDir = await Directory.systemTemp.createTemp(
      'project_import_test_assets_',
    );

    // ProviderContainer is now initialized in the group or test
    // where expectedDbPath is known.
  });

  tearDown(() async {
    // container.dispose(); // Dispose if initialized in group/test
    // Clean up the temporary directory created in setUp
    if (await tempTestDir.exists()) {
      await tempTestDir.delete(recursive: true);
    }
  });

  group('ProjectImportService Tests', () {
    // Use PickedFileResult as that is what importProject currently expects
    late PickedFileResult testPickedFile;
    final now = DateTime.now();
    const projectId = 1;
    final expectedProjectName = 'My Novel';
    final expectedSourceFileName = 'My Novel.txt';
    late String actualSourceFilePath; // Path for the temporary file
    late String expectedDbPath;
    final testContent = 'This is the content of the novel.';
    late MockDatabaseHelper
    newProjectMockDbHelper; // Declare here to be accessible in setUp and test

    setUp(() async {
      // This setUp is for the group
      actualSourceFilePath = p.join(tempTestDir.path, expectedSourceFileName);
      // Create a dummy file so the path is valid for File operations inside the service
      await File(actualSourceFilePath).writeAsString(testContent);

      testPickedFile = PickedFileResult(
        name: expectedSourceFileName,
        path: actualSourceFilePath, // Use the path of the created temp file
        content:
            testContent, // Content might not be directly used if service reads from path
      );

      expectedDbPath = p.join(
        mockAppDocumentsPath,
        'project_databases',
        'My_Novel.db',
      );

      // Initialize mocks that depend on expectedDbPath
      newProjectMockDbHelper = MockDatabaseHelper();
      when(newProjectMockDbHelper.db).thenReturn(mockSqfliteDatabase);
      when(
        newProjectMockDbHelper.init(expectedDbPath, SchemaType.project),
      ).thenAnswer((_) async {});

      // Initialize container here, now that expectedDbPath and newProjectMockDbHelper are known
      container = ProviderContainer(
        overrides: [
          projectServiceProvider.overrideWith(
            (ref) => Future.value(mockProjectService),
          ),
          masterDatabaseHelperProvider.overrideWith(
            (ref) => Future.value(mockMasterDbHelper),
          ),
          fileParserServiceProvider.overrideWithValue(mockFileParserService),
          projectDatabaseHelperProvider(
            expectedDbPath,
          ).overrideWith((ref) => Future.value(newProjectMockDbHelper)),
        ],
      );
    });

    tearDown(() {
      container.dispose(); // Dispose the container after each test in the group
    });

    test(
      'importProject should create project, parse file, update word count, and return project',
      () async {
        // Arrange
        // Container is now set up in the group\'s setUp
        final projectImportService = await container.read(
          projectImportServiceProvider.future,
        );
        const parsedWordCount = 123;
        final parsedChaptersData = [
          {'title': 'Chapter 1'},
        ];
        final parseFileResultMap = {
          'wordCount': parsedWordCount,
          'chapters': parsedChaptersData,
        };

        // Mock ProjectService.createProject
        when(mockProjectService.createProject(any)).thenAnswer((
          invocation,
        ) async {
          final Project projectArg = invocation.positionalArguments[0];
          return projectArg.copyWith(
            projectId: projectId,
            wordCount: 0, // Explicitly 0 from create
          );
        });

        // Mock ProjectService.updateProject
        when(mockProjectService.updateProject(any)).thenAnswer((_) async => 1);

        // The projectDatabaseHelperProvider override is now handled in the group\'s setUp.
        // No need to updateOverrides or re-mock newProjectMockDbHelper here.

        // Mock FileParserService.parseFile
        // It will be called with a File object (created from testPickedFile.path)
        // and the project's database (mockSqfliteDatabase via newProjectMockDbHelper.db)
        // Ensure the mock returns Future<Map<String, dynamic>>
        when(
          mockFileParserService.parseFile(
            any, // File object
            any, // Database object
            projectId,
          ),
        ).thenAnswer((invocation) async {
          // Check the File argument
          final fileArg = invocation.positionalArguments[0] as File;
          expect(fileArg.path, actualSourceFilePath);
          // Check the Database argument
          expect(invocation.positionalArguments[1], mockSqfliteDatabase);
          return Future.value(
            parseFileResultMap,
          ); // Explicitly return Future.value()
        });

        // Act
        final newProject = await projectImportService.importProject(
          testPickedFile, // Pass the PickedFileResult
        );

        // Assert
        expect(newProject, isNotNull);
        expect(newProject?.projectId, projectId);
        expect(newProject?.projectName, expectedProjectName);
        expect(newProject?.sourcePath, actualSourceFilePath);
        expect(newProject?.dbPath, expectedDbPath);
        expect(newProject?.wordCount, parsedWordCount);

        // Verify ProjectService.createProject was called
        final createVerification = verify(
          mockProjectService.createProject(captureAny),
        );
        createVerification.called(1);
        final capturedInitialProject =
            createVerification.captured.single as Project;
        expect(capturedInitialProject.projectName, expectedProjectName);
        expect(
          capturedInitialProject.sourcePath,
          actualSourceFilePath,
        ); // Path should be from PickedFileResult
        expect(capturedInitialProject.dbPath, expectedDbPath);
        expect(capturedInitialProject.wordCount, 0);
        // Check dates approximately if they are set by the service before createProject
        expect(
          capturedInitialProject.createdAt.difference(now).inSeconds.abs() < 2,
          isTrue,
        );
        expect(
          capturedInitialProject.lastImportedAt
                  .difference(now)
                  .inSeconds
                  .abs() <
              2,
          isTrue,
        );

        // Verify ProjectService.updateProject was called
        final updateVerification = verify(
          mockProjectService.updateProject(captureAny),
        );
        updateVerification.called(1);
        final capturedUpdatedProject =
            updateVerification.captured.single as Project;
        expect(capturedUpdatedProject.projectId, projectId);
        expect(capturedUpdatedProject.wordCount, parsedWordCount);
        expect(
          capturedUpdatedProject.lastImportedAt
                  .difference(now)
                  .inSeconds
                  .abs() <
              2, // Allow for slight time difference
          isTrue,
        );

        // The DatabaseHelper.init() method is called by the projectDatabaseHelperProvider
        // when the DatabaseHelper is created. The ProjectImportService receives an already
        // initialized helper. Therefore, we don't verify newProjectMockDbHelper.init() here.
        // We do, however, rely on newProjectMockDbHelper.db being correctly stubbed and used.

        // Verify FileParserService.parseFile was called correctly
        final parseFileVerification = verify(
          mockFileParserService.parseFile(
            captureAny, // File object
            captureAny, // Database object
            projectId,
          ),
        );
        parseFileVerification.called(1);
        expect(
          (parseFileVerification.captured[0] as File).path,
          actualSourceFilePath,
        );
        expect(parseFileVerification.captured[1], mockSqfliteDatabase);
      },
    );
  });
}
