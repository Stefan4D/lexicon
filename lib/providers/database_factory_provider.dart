import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sqflite_mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final databaseFactoryProvider = Provider<DatabaseFactory>((ref) {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  } else {
    return sqflite_mobile.databaseFactory;
  }
});
