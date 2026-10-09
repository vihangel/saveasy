import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'community_subscription_cubit.freezed.dart';
part 'community_subscription_state.dart';

/// Inscrição (assinatura) numa comunidade. Os planos vêm da comunidade; o
/// pagamento passa pelo checkout na tela.
class CommunitySubscriptionCubit extends Cubit<CommunitySubscriptionState> {
  CommunitySubscriptionCubit(this.communityId, this._users, this._wallet, this._session)
    : super(const CommunitySubscriptionState());

  final String communityId;
  final UserRepository _users;
  final WalletRepository _wallet;
  final SessionCubit _session;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    try {
      final (community, plans) = await (_users.getById(communityId), _wallet.communityPlans(communityId)).wait;
      emit(
        state.copyWith(
          status: ViewStatus.success,
          community: community,
          plans: plans,
          planId: plans.plans.firstOrNull?.id,
        ),
      );
    } on ParallelWaitError {
      emit(state.copyWith(status: ViewStatus.failure));
    }
  }

  void selectPlan(String planId) => emit(state.copyWith(planId: planId));

  PaymentIntent? get intent => state.planId == null ? null : PaymentIntent.subscription(planId: state.planId!);

  Future<void> paid(AppUser user) async {
    _session.updateUser(user);
    emit(state.copyWith(done: true));
  }

  Future<void> cancel() async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      final plans = await _wallet.cancelSubscription(communityId);
      emit(state.copyWith(submitting: false, plans: plans));
    } on AppException catch (e) {
      emit(state.copyWith(submitting: false, error: e.message));
    }
  }
}
