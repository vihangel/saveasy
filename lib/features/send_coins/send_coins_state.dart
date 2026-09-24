part of 'send_coins_cubit.dart';

@freezed
abstract class SendCoinsState with _$SendCoinsState {
  const factory SendCoinsState({
    @Default(ViewStatus.initial) ViewStatus status,
    AppUser? target,
    Post? post,
    @Default(10) int coins,
    @Default('') String message,
    @Default(false) bool submitting,
    @Default(false) bool done,
    String? error,
  }) = _SendCoinsState;
}
