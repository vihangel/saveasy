import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/view_status.dart';

part 'feed_cubit.freezed.dart';
part 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._posts, this._stories, this._userId) : super(const FeedState());

  final PostRepository _posts;
  final StoryRepository _stories;
  final String _userId;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    try {
      final (posts, stories) = await (
        _posts.feed(tab: state.tab, userId: _userId, category: state.category, query: state.query),
        _stories.stories(),
      ).wait;
      emit(
        state.copyWith(
          status: ViewStatus.success,
          posts: posts,
          stories: stories,
          commentCounts: {for (final p in posts) p.id: _posts.commentCount(p.id)},
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ViewStatus.failure, error: 'Não foi possível carregar o feed.'));
    }
  }

  void selectTab(FeedTab tab) {
    if (tab == state.tab) return;
    emit(state.copyWith(tab: tab));
    load();
  }

  void selectCategory(PostCategory? category) {
    emit(state.copyWith(category: category == state.category ? null : category));
    load();
  }

  void search(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), load);
  }

  Future<void> toggleLike(String postId) async {
    final updated = await _posts.toggleLike(postId);
    _replace(updated);
  }

  Future<void> share(String postId) async {
    final updated = await _posts.share(postId);
    _replace(updated);
  }

  void _replace(Post post) => emit(state.copyWith(posts: [for (final p in state.posts) p.id == post.id ? post : p]));

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
