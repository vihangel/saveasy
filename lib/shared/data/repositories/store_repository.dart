import '../models/models.dart';

/// Lojas das comunidades/empresas: produtos, pedidos e avaliações.
/// Implementações: [MockStoreRepository] e [SupabaseStoreRepository].
abstract interface class StoreRepository {
  Future<List<Product>> products({String query = '', String? sellerId});

  Future<ProductDetail> detail(String productId);

  /// Cria ou edita (quando [product] tem id) um produto do vendedor logado.
  Future<Product> save(Product product);

  Future<void> delete(String productId);

  Future<List<StoreOrder>> myOrders();

  Future<List<StoreOrder>> sellerOrders();

  Future<StoreOrder> updateOrderStatus(String orderId, OrderStatus status);

  Future<ProductDetail> review(String productId, {required int rating, String comment = ''});
}
