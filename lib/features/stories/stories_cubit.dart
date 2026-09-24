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
    final stories = await _repository.stories();
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
    final rewarded = await _repository.rewardAdView(storyId: story.id, userId: _session.user.id);
    if (rewarded != null) {
      _session.updateUser(rewarded);
      emit(state.copyWith(rewardMessage: '+20 moedas por assistir o anúncio!'));
    }
    await _repository.markSeen(story.id);
  }
}
