import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'rewards_cubit.freezed.dart';
part 'rewards_state.dart';

/// Usado tanto na lista (Recompensas - Principal) quanto no detalhe
/// (Recompensa 1/3), que recebem a mesma instância pela rota.
class RewardsCubit extends Cubit<RewardsState> {
  RewardsCubit(this._gamification, this._session) : super(const RewardsState());

  final GamificationRepository _gamification;
  final SessionCubit _session;

  Future<void> load() async {
    emit(state.copyWith(status: state.rewards.isEmpty ? ViewStatus.loading : state.status));
    emit(state.copyWith(status: ViewStatus.success, rewards: await _gamification.rewards()));
  }

  List<Reward> byKind(RewardKind kind) => state.rewards.where((r) => r.kind == kind).toList();

  Future<void> redeem(String rewardId) async {
    emit(state.copyWith(redeemingId: rewardId, error: null, message: null));
    try {
      final (reward, user) = await _gamification.redeem(rewardId: rewardId, userId: _session.user.id);
      _session.updateUser(user);
      emit(
        state.copyWith(
          redeemingId: null,
          rewards: [for (final r in state.rewards) r.id == rewardId ? reward : r],
          message: '"${reward.name}" resgatado! Exiba no seu perfil em Editar Perfil.',
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(redeemingId: null, error: e.message));
    }
  }
}
