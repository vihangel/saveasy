import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'stories_cubit.freezed.dart';
part 'stories_state.dart';

/// Visualizador de stories (Stories 1-4).
class StoriesCubit extends Cubit<StoriesState> {
  StoriesCubit(this._repository, this._session, int initialIndex) : super(StoriesState(index: initialIndex));

  final StoryRepository _repository;
  final SessionCubit _session;

  Future<void> load() async {
    final List<Story> stories;
    try {
      stories = await _repository.stories();
    } on AppException {
      return emit(state.copyWith(status: ViewStatus.failure, finished: true));
    }
    if (stories.isEmpty) return emit(state.copyWith(status: ViewStatus.success, finished: true));
    emit(
      state.copyWith(
        status: ViewStatus.success,
        stories: stories,
        index: state.index.clamp(0, stories.isEmpty ? 0 : stories.length - 1),
      ),
    );
    await _markCurrentSeen();
  }

  Story get current => state.stories[state.index];

  Future<void> next() async {
    if (state.index >= state.stories.length - 1) return emit(state.copyWith(finished: true));
    emit(state.copyWith(index: state.index + 1, rewardMessage: null));
    await _markCurrentSeen();
  }

  void previous() {
    if (state.index > 0) emit(state.copyWith(index: state.index - 1, rewardMessage: null));
  }

  Future<void> _markCurrentSeen() async {
    if (state.stories.isEmpty) return;
    final story = current;
    if (story.seen) return;
    emit(state.copyWith(stories: [for (final s in state.stories) s.id == story.id ? s.copyWith(seen: true) : s]));
    try {
      final rewarded = await _repository.view(story.id, userId: _session.user.id);
      if (rewarded != null) {
        _session.updateUser(rewarded);
        emit(state.copyWith(rewardMessage: '+20 moedas por assistir o anúncio!'));
      }
    } on AppException {
      // Visualização é só registro: falhar não deve travar o story.
    }
  }

  /// Exclui o story atual (só o autor vê a opção).
  Future<void> deleteCurrent() async {
    final story = current;
    await _repository.delete(story.id);
    final stories = state.stories.where((s) => s.id != story.id).toList();
    if (stories.isEmpty) return emit(state.copyWith(stories: stories, finished: true));
    emit(state.copyWith(stories: stories, index: state.index.clamp(0, stories.length - 1)));
  }
}
