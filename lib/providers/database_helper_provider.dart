import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_helper.dart';
import 'database_factory_provider.dart';

final databaseHelperProvider = FutureProvider<DatabaseHelper>((ref) async {
  final factory = ref.watch(databaseFactoryProvider);
  final helper = DatabaseHelper(factory);
  await helper.init();
  return helper;
});
