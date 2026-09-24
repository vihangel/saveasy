import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
abstract class Comment with _$Comment {
  const factory Comment({
    required String id,
    required String postId,
    required String authorName,
    required String text,
    required DateTime createdAt,
    @Default(0) int likes,
    @Default(false) bool liked,
    @Default(0) int replies,
    String? lastReplyAuthor,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}
