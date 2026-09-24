part of 'create_post_cubit.dart';

@freezed
abstract class CreatePostState with _$CreatePostState {
  const factory CreatePostState({
    required PostType type,
    String? subtype,
    @Default(<String>[]) List<String> tags,
    @Default(<PostCategory>[]) List<PostCategory> categories,
    DateTime? startsAt,
    DateTime? endsAt,
    String? imageUrl,
    String? adPlan,
    @Default(ViewStatus.initial) ViewStatus status,
    String? error,
    String? createdPostId,
  }) = _CreatePostState;
}
