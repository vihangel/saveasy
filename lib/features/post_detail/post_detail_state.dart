part of 'post_detail_cubit.dart';

@freezed
abstract class PostDetailState with _$PostDetailState {
  const factory PostDetailState({
    @Default(ViewStatus.initial) ViewStatus status,
    Post? post,
    AppUser? author,
    @Default(<Comment>[]) List<Comment> comments,
    @Default(false) bool participating,
    @Default(false) bool sendingComment,
    String? error,

    /// Mensagem pontual (ex.: recompensa recebida) exibida uma vez pela tela.
    String? message,
  }) = _PostDetailState;
}
