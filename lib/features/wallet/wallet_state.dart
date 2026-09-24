part of 'wallet_cubit.dart';

@freezed
abstract class WalletState with _$WalletState {
  const factory WalletState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<WalletTransaction>[]) List<WalletTransaction> history,
    CoinPackage? buying,
    String? error,
    String? message,
  }) = _WalletState;
}
