import 'package:saveeasy2026/shared/data/datasources/local_storage.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Banco mockado limpo (seed) para cada teste.
Future<(MockDatabase, LocalStorage)> createTestDatabase() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.create();
  final db = MockDatabase(storage);
  await db.load();
  return (db, storage);
}
