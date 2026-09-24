import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'community_subscription_cubit.freezed.dart';
part 'community_subscription_state.dart';

class CommunitySubscriptionCubit extends Cubit<CommunitySubscriptionState> {
  CommunitySubscriptionCubit(this.communityId, this._users, this._wallet, this._session)
    : super(const CommunitySubscriptionState());

  final String communityId;
  final UserRepository _users;
  final WalletRepository _wallet;
  final SessionCubit _session;

  static const plans = {'Mensal': 9.90, 'Anual': 99.00};

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    emit(state.copyWith(status: ViewStatus.success, community: await _users.getById(communityId)));
  }

  void selectPlan(String plan) => emit(state.copyWith(plan: plan));

  Future<void> subscribe() async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      final user = await _wallet.subscribe(
        userId: _session.user.id,
        communityId: communityId,
        price: plans[state.plan]!,
      );
      _session.updateUser(user);
      emit(state.copyWith(submitting: false, done: true));
    } on AppException catch (e) {
      emit(state.copyWith(submitting: false, error: e.message));
    }
  }
}
