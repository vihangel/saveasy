part of 'community_subscription_cubit.dart';

@freezed
abstract class CommunitySubscriptionState with _$CommunitySubscriptionState {
  const factory CommunitySubscriptionState({
    @Default(ViewStatus.initial) ViewStatus status,
    AppUser? community,
    @Default('Mensal') String plan,
    @Default(false) bool submitting,
    @Default(false) bool done,
    String? error,
  }) = _CommunitySubscriptionState;
}
