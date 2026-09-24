import 'package:freezed_annotation/freezed_annotation.dart';

part 'reward.freezed.dart';
part 'reward.g.dart';

enum RewardKind {
  @JsonValue('cover')
  cover('Capas'),
  @JsonValue('badge')
  badge('Selos'),
  @JsonValue('title')
  title('Títulos');

  const RewardKind(this.label);

  final String label;
}

/// Item personalizável que o usuário troca por moedas.
@freezed
abstract class Reward with _$Reward {
  const factory Reward({
    required String id,
    required RewardKind kind,
    required String name,
    required String description,
    required int price,
    required String sponsor,
    @Default('star') String icon,
    @Default(false) bool owned,
  }) = _Reward;

  factory Reward.fromJson(Map<String, dynamic> json) => _$RewardFromJson(json);
}
