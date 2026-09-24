part of 'rewards_cubit.dart';

@freezed
abstract class RewardsState with _$RewardsState {
  const factory RewardsState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<Reward>[]) List<Reward> rewards,
    String? redeemingId,
    String? error,
    String? message,
  }) = _RewardsState;
}
