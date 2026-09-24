import 'package:freezed_annotation/freezed_annotation.dart';

import 'account_type.dart';

part 'post.freezed.dart';
part 'post.g.dart';

enum PostType {
  @JsonValue('donation')
  donation('Doação'),
  @JsonValue('event')
  event('Evento'),
  @JsonValue('social_action')
  socialAction('Ação Social'),
  @JsonValue('activity')
  activity('Atividade'),
  @JsonValue('tutorial')
  tutorial('Tutorial'),
  @JsonValue('discussion')
  discussion('Discussão'),
  @JsonValue('ad')
  ad('Propaganda');

  const PostType(this.label);

  final String label;
}

/// Categorias do filtro do feed.
enum PostCategory {
  @JsonValue('education')
  education('Educação'),
  @JsonValue('health')
  health('Saúde'),
  @JsonValue('animal')
  animal('Animais'),
  @JsonValue('environment')
  environment('Meio ambiente'),
  @JsonValue('children')
  children('Crianças'),
  @JsonValue('culture')
  culture('Cultura');

  const PostCategory(this.label);

  final String label;
}

/// Uma publicação do feed. Os campos opcionais dependem do [type].
@freezed
abstract class Post with _$Post {
  const Post._();

  const factory Post({
    required String id,
    required PostType type,
    required String title,
    required String description,
    required String authorId,
    required String authorName,
    required AccountType authorType,
    required DateTime createdAt,

    /// Capa escolhida pelo autor (referência do ImageStorage).
    String? imageUrl,
    String? authorAvatarUrl,
    @Default(<PostCategory>[]) List<PostCategory> categories,
    @Default(<String>[]) List<String> tags,
    @Default('') String subtype,
    @Default(0) int likes,
    @Default(0) int shares,
    @Default(false) bool liked,
    @Default(false) bool saved,
    @Default(10) int rewardCoins,
    @Default(50) int rewardXp,
    // Doação
    double? targetAmount,
    @Default(0) double raisedAmount,
    @Default(false) bool recurring,
    DateTime? endsAt,
    // Evento / Ação social / Atividade
    DateTime? startsAt,
    String? location,
    String? link,
    @Default(0) int attending,
    int? capacity,
    @Default(false) bool confirmed,
    // Tutorial
    int? durationMinutes,
    @Default(<String>[]) List<String> steps,
    // Propaganda
    String? adPlan,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  double get progress {
    final target = targetAmount;
    if (target == null || target == 0) return 0;
    return (raisedAmount / target).clamp(0, 1);
  }

  double get remainingAmount => ((targetAmount ?? 0) - raisedAmount).clamp(0, double.infinity);

  bool get isFinished {
    final end = endsAt ?? startsAt;
    return end != null && end.isBefore(DateTime.now());
  }
}
