part of 'donate_cubit.dart';

/// Doar com dinheiro (Pix/cartão) ou com moedas (pagas pelo fundo de doações).
enum DonateMode { money, coins }

@freezed
abstract class DonateState with _$DonateState {
  const factory DonateState({
    @Default(ViewStatus.initial) ViewStatus status,
    Post? post,
    DonationFund? fund,
    @Default(DonateMode.money) DonateMode mode,
    @Default(0) double amount,
    @Default(0) int coins,
    @Default(false) bool done,
    @Default(false) bool submitting,
    String? error,
  }) = _DonateState;
}
