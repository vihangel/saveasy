part of 'store_cubit.dart';

@freezed
abstract class StoreState with _$StoreState {
  const factory StoreState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<Product>[]) List<Product> products,
    @Default('') String query,
    String? buyingId,
    String? error,
    String? message,
  }) = _StoreState;
}
