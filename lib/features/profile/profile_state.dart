part of 'profile_cubit.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const ProfileState._();

  const factory ProfileState({
    @Default(ViewStatus.initial) ViewStatus status,
    AppUser? user,
    @Default(<Post>[]) List<Post> posts,
    @Default(<Reward>[]) List<Reward> badges,
    Reward? title,
    @Default(<WalletTransaction>[]) List<WalletTransaction> history,
    @Default(false) bool isMe,
    String? error,
  }) = _ProfileState;
}
