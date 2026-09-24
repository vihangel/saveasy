part of 'edit_profile_cubit.dart';

@freezed
abstract class EditProfileState with _$EditProfileState {
  const factory EditProfileState({
    @Default(ViewStatus.initial) ViewStatus status,
    required AppUser user,
    @Default(<Reward>[]) List<Reward> ownedBadges,
    @Default(<Reward>[]) List<Reward> ownedTitles,
    @Default(false) bool saving,
    @Default(false) bool saved,
    String? error,
  }) = _EditProfileState;
}
