part of 'achievements_cubit.dart';

@freezed
abstract class AchievementsState with _$AchievementsState {
  const factory AchievementsState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<Achievement>[]) List<Achievement> items,
    String? message,
  }) = _AchievementsState;
}
