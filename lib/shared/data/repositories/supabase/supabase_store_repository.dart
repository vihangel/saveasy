import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../app_exception.dart';
import '../store_repository.dart';
import 'supabase_guard.dart';

/// Loja via RPC (supabase/migrations/*_payments_store.sql). Compras passam
/// pelo [WalletRepository.createPayment] (tipo pedido).
class SupabaseStoreRepository implements StoreRepository {
  SupabaseStoreRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Product>> products({String query = '', String? sellerId}) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>(
      'store_products',
      params: {'p_query': query.trim(), 'p_seller_id': sellerId},
    );
    return list.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();
  });

  @override
  Future<ProductDetail> detail(String productId) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>?>('product_detail', params: {'p_product_id': _id(productId)});
    if (json == null) throw const AppException('Produto não encontrado.');
    return ProductDetail.fromJson(json);
  });

  @override
  Future<Product> save(Product product) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'save_product',
      params: {
        'p': {
          'id': product.id.isEmpty ? null : product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'icon': product.icon,
          'stock': product.stock,
          'active': product.active,
        },
      },
    );
    return Product.fromJson(json);
  });

  @override
  Future<void> delete(String productId) =>
      supabaseGuard(() => _client.rpc<void>('delete_product', params: {'p_product_id': _id(productId)}));

  @override
  Future<List<StoreOrder>> myOrders() => _orders('my_orders');

  @override
  Future<List<StoreOrder>> sellerOrders() => _orders('seller_orders');

  @override
  Future<StoreOrder> updateOrderStatus(String orderId, OrderStatus status) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'update_order_status',
      params: {'p_order_id': _id(orderId), 'p_status': status.name},
    );
    return StoreOrder.fromJson(json);
  });

  @override
  Future<ProductDetail> review(String productId, {required int rating, String comment = ''}) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'review_product',
      params: {'p_product_id': _id(productId), 'p_rating': rating, 'p_comment': comment},
    );
    return ProductDetail.fromJson(json);
  });

  Future<List<StoreOrder>> _orders(String fn) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>(fn);
    return list.map((o) => StoreOrder.fromJson(o as Map<String, dynamic>)).toList();
  });

  int _id(String id) {
    final parsed = int.tryParse(id);
    if (parsed == null) throw const AppException('Item não encontrado.');
    return parsed;
  }
}
