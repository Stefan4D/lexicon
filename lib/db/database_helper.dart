// External imports
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:sqflite_common_ffi/windows/sqflite_ffi_setup.dart';
import 'package:flutter/services.dart';

// Project imports
import 'package:lexicon/db/models/project.dart';

class DatabaseHelper {
  // Private constructor
  DatabaseHelper._privateConstructor();

  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Getter for the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    // Define the path to the database
    String path = await getDatabasesPath();
    String dbPath = '$path/lexicon.db';

    // Open the database
    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  // Create the database tables
  Future<void> _onCreate(Database db, int version) async {
    // Open the .sql file for database schema
    String sql = await rootBundle.loadString('assets/database_schema.sql');
    // Example table creation
    await db.execute(sql);
  }

  // Close the database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Get all projects
  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('projects');
    return List.generate(maps.length, (i) {
      return Project(id: maps[i]['id'], name: maps[i]['name']);
    });
  }

  // // Factory constructor to return the singleton instance
  // factory DatabaseHelper() {
  //   return _instance;
  // }

  // // Example method to demonstrate functionality
  // void exampleMethod() {
  //   print("This is an example method in the DatabaseHelper class.");
  // }
}
