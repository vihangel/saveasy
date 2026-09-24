import 'package:freezed_annotation/freezed_annotation.dart';

import 'post.dart';

part 'story.freezed.dart';
part 'story.g.dart';

@freezed
abstract class Story with _$Story {
  const factory Story({
    required String id,
    required String authorId,
    required String authorName,
    required PostType type,
    required String text,
    required DateTime createdAt,
    String? postId,
    String? imageUrl,
    String? authorAvatarUrl,
    @Default(false) bool seen,
  }) = _Story;

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
}
