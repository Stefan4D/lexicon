import 'package:sqflite_common/sqlite_api.dart';
import 'package:flutter/services.dart';

class DatabaseHelper {
  final DatabaseFactory _databaseFactory;
  Database? _db;

  DatabaseHelper(this._databaseFactory);

  Future<void> init() async {
    _db = await _databaseFactory.openDatabase('my_database.db');
    String sql = await rootBundle.loadString('assets/database_schema.sql');
    await _db!.execute(sql);
  }

  Future<void> insertProduct(String title) async {
    await _db?.insert('Product', {'title': title});
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    return await _db?.query('Product') ?? [];
  }

  Future<void> close() async {
    await _db?.close();
  }
}
