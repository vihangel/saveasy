part of 'donate_cubit.dart';

@freezed
abstract class DonateState with _$DonateState {
  const factory DonateState({
    @Default(ViewStatus.initial) ViewStatus status,
    Post? post,
    @Default(0) double amount,
    @Default(false) bool done,
    @Default(false) bool submitting,
    String? error,
  }) = _DonateState;
}
