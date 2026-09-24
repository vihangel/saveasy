import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

enum StoreSection {
  @JsonValue('popular')
  popular('De comunidades populares'),
  @JsonValue('top_rated')
  topRated('Produtos bem avaliados'),
  @JsonValue('nearby')
  nearby('De comunidades na sua região');

  const StoreSection(this.label);

  final String label;
}

/// Produto vendido nas lojas das comunidades.
@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String description,
    required double price,
    required String communityId,
    required String communityName,
    required StoreSection section,
    @Default('shopping_bag') String icon,
    @Default(4.5) double rating,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
