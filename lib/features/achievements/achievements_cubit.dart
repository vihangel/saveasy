import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'achievements_cubit.freezed.dart';
part 'achievements_state.dart';

class AchievementsCubit extends Cubit<AchievementsState> {
  AchievementsCubit(this._gamification, this._session) : super(const AchievementsState());

  final GamificationRepository _gamification;
  final SessionCubit _session;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    emit(state.copyWith(status: ViewStatus.success, items: await _gamification.achievements()));
  }

  Future<void> claim(String id) async {
    final (achievement, user) = await _gamification.claim(achievementId: id, userId: _session.user.id);
    _session.updateUser(user);
    emit(
      state.copyWith(
        items: [for (final a in state.items) a.id == id ? achievement : a],
        message: '+${achievement.rewardCoins} moedas resgatadas!',
      ),
    );
  }
}
