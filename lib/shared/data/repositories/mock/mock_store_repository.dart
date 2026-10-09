import '../../datasources/mock_database.dart';
import '../../models/models.dart';
import '../app_exception.dart';
import '../store_repository.dart';

/// Loja local (catálogo do seed; pedidos só em memória).
class MockStoreRepository implements StoreRepository {
  MockStoreRepository(this._db);

  final MockDatabase _db;
  final _orders = <StoreOrder>[];

  @override
  Future<List<Product>> products({String query = '', String? sellerId}) async {
    await _db.delay();
    final q = query.trim().toLowerCase();
    return _db.products
        .where((p) => sellerId == null || p.communityId == sellerId)
        .where((p) => q.isEmpty || '${p.name} ${p.communityName}'.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<ProductDetail> detail(String productId) async {
    await _db.delay();
    final product = _db.products.where((p) => p.id == productId).firstOrNull;
    if (product == null) throw const AppException('Produto não encontrado.');
    return ProductDetail(product: product);
  }

  @override
  Future<Product> save(Product product) async {
    final saved = product.id.isEmpty ? product.copyWith(id: _db.newId('pr')) : product;
    _db.products = [..._db.products.where((p) => p.id != saved.id), saved];
    return saved;
  }

  @override
  Future<void> delete(String productId) async => _db.products = _db.products.where((p) => p.id != productId).toList();

  @override
  Future<List<StoreOrder>> myOrders() async => _orders;

  @override
  Future<List<StoreOrder>> sellerOrders() async => const [];

  @override
  Future<StoreOrder> updateOrderStatus(String orderId, OrderStatus status) async {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) throw const AppException('Pedido não encontrado.');
    return _orders[i] = _orders[i].copyWith(status: status);
  }

  @override
  Future<ProductDetail> review(String productId, {required int rating, String comment = ''}) async {
    final detail = await this.detail(productId);
    return detail.copyWith(
      reviews: [ProductReview(rating: rating, comment: comment, createdAt: DateTime.now(), authorName: 'Você')],
    );
  }
}
