import 'package:sqflite_common/sqlite_api.dart';
import 'package:flutter/services.dart';

enum SchemaType { master, project }

class DatabaseHelper {
  final DatabaseFactory _databaseFactory;
  Database? _db;
  String? _dbPath;

  DatabaseHelper(this._databaseFactory);

  Database? get db => _db; // Add this getter

  Future<void> init(String dbPath, SchemaType schemaType) async {
    _dbPath = dbPath;
    _db = await _databaseFactory.openDatabase(
      _dbPath!,
      options: OpenDatabaseOptions(
        version: 1, // Initial version
        onCreate: (db, version) => _onCreateDb(db, version, schemaType),
        // onUpgrade: _onUpgradeDb, // For future migrations
      ),
    );
  }

  Future<void> _onCreateDb(
    Database db,
    int version,
    SchemaType schemaType,
  ) async {
    String schemaPath;
    switch (schemaType) {
      case SchemaType.master:
        schemaPath = 'lib/assets/master_schema.sql';
        break;
      case SchemaType.project:
        schemaPath = 'lib/assets/project_schema.sql';
        break;
    }

    String sqlScript = await rootBundle.loadString(schemaPath);

    // Split the script into individual statements.
    List<String> statements = sqlScript.split(';');

    for (String statement in statements) {
      String cleanedStatement =
          statement.replaceAll(RegExp(r'--.*(\\n|$)'), '').trim();
      if (cleanedStatement.isNotEmpty) {
        await db.execute(cleanedStatement);
      }
    }
  }

  // Example of how you might add a project to the master database
  // This would typically be in a service class, not directly in DatabaseHelper
  // Future<int> addProjectToMaster(String projectName, String sourcePath, String projectDbPath) async {
  //   if (_db == null) throw Exception("Database not initialized");
  //   final now = DateTime.now().toIso8601String();
  //   return await _db!.insert('projects', {
  //     'project_name': projectName,
  //     'source_path': sourcePath,
  //     'db_path': projectDbPath,
  //     'last_imported_at': now,
  //     'created_at': now,
  //   });
  // }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
