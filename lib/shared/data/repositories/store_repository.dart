import '../datasources/mock_database.dart';
import '../models/models.dart';

class StoreRepository {
  StoreRepository(this._db);

  final MockDatabase _db;

  Future<List<Product>> products({String query = ''}) async {
    await _db.delay();
    final q = query.trim().toLowerCase();
    return _db.products.where((p) => q.isEmpty || '${p.name} ${p.communityName}'.toLowerCase().contains(q)).toList();
  }

  Future<Product> getById(String id) async {
    await _db.delay();
    return _db.products.firstWhere((p) => p.id == id);
  }
}
