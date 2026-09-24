part of 'stories_cubit.dart';

@freezed
abstract class StoriesState with _$StoriesState {
  const factory StoriesState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<Story>[]) List<Story> stories,
    @Default(0) int index,
    @Default(false) bool finished,
    String? rewardMessage,
  }) = _StoriesState;
}
