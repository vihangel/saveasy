import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'post_detail_cubit.freezed.dart';
part 'post_detail_state.dart';

class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit({required this.postId, required this._posts, required this._users, required this._session})
    : super(const PostDetailState());

  final String postId;
  final PostRepository _posts;
  final UserRepository _users;
  final SessionCubit _session;

  Post get _post => state.post!;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    try {
      final post = await _posts.getById(postId);
      final (author, comments) = await (_users.getById(post.authorId), _posts.comments(postId)).wait;
      emit(state.copyWith(status: ViewStatus.success, post: post, author: author, comments: comments));
    } catch (_) {
      emit(state.copyWith(status: ViewStatus.failure, error: 'Publicação não encontrada.'));
    }
  }

  Future<void> toggleLike() async => emit(state.copyWith(post: await _posts.toggleLike(postId)));

  Future<void> toggleSave() async => emit(state.copyWith(post: await _posts.toggleSave(postId)));

  Future<void> share() async => emit(state.copyWith(post: await _posts.share(postId), message: 'Link copiado!'));

  Future<void> addComment(String text) async {
    if (text.trim().isEmpty) return;
    emit(state.copyWith(sendingComment: true));
    final comment = await _posts.addComment(postId: postId, authorName: _session.user.name, text: text);
    emit(state.copyWith(sendingComment: false, comments: [comment, ...state.comments]));
  }

  Future<void> toggleCommentLike(String commentId) async {
    final updated = await _posts.toggleCommentLike(commentId);
    emit(state.copyWith(comments: [for (final c in state.comments) c.id == commentId ? updated : c]));
  }

  /// Confirma presença (evento) ou participação (ação social / atividade).
  /// Retorna true quando a confirmação foi feita agora.
  Future<bool> toggleParticipation() async {
    emit(state.copyWith(participating: true));
    if (_post.confirmed) {
      final (post, _) = await _posts.cancelParticipation(postId: postId, userId: _session.user.id);
      emit(state.copyWith(participating: false, post: post, message: 'Participação cancelada.'));
      return false;
    }
    final (post, user) = await _posts.participate(postId: postId, userId: _session.user.id);
    _session.updateUser(user);
    emit(
      state.copyWith(
        participating: false,
        post: post,
        message: post.type == PostType.event
            ? null
            : 'Participação confirmada! +${post.rewardCoins} moedas e +${post.rewardXp} XP',
      ),
    );
    return true;
  }

  Future<void> toggleFollowAuthor() async {
    final me = await _users.toggleFollow(meId: _session.user.id, targetId: _post.authorId);
    _session.updateUser(me);
    emit(state.copyWith(author: await _users.getById(_post.authorId)));
  }

  /// Recarrega o post depois de voltar de um fluxo (doação, envio de moedas).
  Future<void> refreshPost() async => emit(state.copyWith(post: await _posts.getById(postId)));

  void messageShown() => emit(state.copyWith(message: null));
}
