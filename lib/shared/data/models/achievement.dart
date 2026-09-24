import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

@freezed
abstract class Achievement with _$Achievement {
  const Achievement._();

  const factory Achievement({
    required String id,
    required String title,
    required String description,
    required int goal,
    required int current,
    required int rewardCoins,
    @Default(false) bool daily,
    @Default(false) bool claimed,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);

  double get progress => (current / goal).clamp(0, 1);

  bool get completed => current >= goal;
}
