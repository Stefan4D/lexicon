import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'package:lexicon/models/project.dart';
import 'package:lexicon/models/series.dart';
import 'package:lexicon/providers/database_helper_provider.dart';
import 'package:lexicon/db/database_helper.dart';

// Provider for the ProjectService - will be changed to FutureProvider
final projectServiceProvider = FutureProvider<ProjectService>((ref) async {
  final masterDbHelper = await ref.watch(masterDatabaseHelperProvider.future);
  return ProjectService(masterDbHelper);
});

class ProjectService {
  final DatabaseHelper
  _masterDbHelper; // Changed from AsyncValue<DatabaseHelper>

  ProjectService(this._masterDbHelper); // Updated constructor

  Database _getDbInstance() {
    // Renamed from _getDb, made synchronous
    if (_masterDbHelper.db == null) {
      throw StateError(
        "Database instance in MasterDatabaseHelper is null after initialization.",
      );
    }
    return _masterDbHelper.db!;
  }

  // Add a new project
  Future<Project> createProject(Project projectData) async {
    final db = _getDbInstance();
    // The projectData comes with all fields set, including dates and initial wordCount.
    // projectId should be null for a new project.
    final Map<String, dynamic> projectMap = projectData.toMap();

    final id = await db.insert('projects', projectMap);
    if (id == 0) {
      // Or check for -1 depending on sqflite's error indication
      throw Exception(
        'Failed to insert project into database. Received ID: $id',
      );
    }
    return projectData.copyWith(projectId: id);
  }

  // Get all projects
  Future<List<Project>> getAllProjects() async {
    final db = _getDbInstance(); // Changed
    final List<Map<String, dynamic>> maps = await db.query('projects');
    return List.generate(maps.length, (i) {
      return Project.fromMap(maps[i]);
    });
  }

  // Get a project by ID
  Future<Project?> getProjectById(int projectId) async {
    final db = _getDbInstance(); // Changed
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    if (maps.isNotEmpty) {
      return Project.fromMap(maps.first);
    }
    return null;
  }

  // Update an existing project
  Future<int> updateProject(Project project) async {
    final db = _getDbInstance(); // Changed
    return await db.update(
      'projects',
      project.toMap(),
      where: 'project_id = ?',
      whereArgs: [project.projectId],
    );
  }

  // Update project name
  Future<Project?> updateProjectName(int projectId, String newName) async {
    final db = _getDbInstance();
    final count = await db.update(
      'projects',
      {'project_name': newName},
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    if (count > 0) {
      return await getProjectById(projectId); // Fetch the updated project
    }
    return null; // Or throw an exception if project not found/not updated
  }

  // Delete a project
  Future<int> deleteProject(int projectId) async {
    final db = _getDbInstance(); // Changed
    // Consider also deleting the associated project-specific .db file from the filesystem here
    return await db.delete(
      'projects',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
  }

  // --- Series Management ---

  // Add a new series
  Future<int> addSeries(String seriesName) async {
    final db = _getDbInstance(); // Changed
    final series = Series(seriesName: seriesName);
    return await db.insert('series', series.toMap());
  }

  // Get all series
  Future<List<Series>> getAllSeries() async {
    final db = _getDbInstance(); // Changed
    final List<Map<String, dynamic>> maps = await db.query('series');
    return List.generate(maps.length, (i) {
      return Series.fromMap(maps[i]);
    });
  }

  // Get a series by ID
  Future<Series?> getSeriesById(int seriesId) async {
    final db = _getDbInstance(); // Changed
    final List<Map<String, dynamic>> maps = await db.query(
      'series',
      where: 'series_id = ?',
      whereArgs: [seriesId],
    );
    if (maps.isNotEmpty) {
      return Series.fromMap(maps.first);
    }
    return null;
  }

  // Update an existing series
  Future<int> updateSeries(Series series) async {
    final db = _getDbInstance(); // Changed
    return await db.update(
      'series',
      series.toMap(),
      where: 'series_id = ?',
      whereArgs: [series.seriesId],
    );
  }

  // Delete a series
  Future<int> deleteSeries(int seriesId) async {
    final db = _getDbInstance(); // Changed
    // Note: projects linked to this series will have their series_id set to NULL due to schema definition
    return await db.delete(
      'series',
      where: 'series_id = ?',
      whereArgs: [seriesId],
    );
  }
}
