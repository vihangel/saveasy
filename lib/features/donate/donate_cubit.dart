import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'donate_cubit.freezed.dart';
part 'donate_state.dart';

/// Fluxo Doar 1 → 2 → 3/4: escolher valor, confirmar e ver as recompensas.
class DonateCubit extends Cubit<DonateState> {
  DonateCubit(this.postId, this._posts, this._wallet, this._session) : super(const DonateState());

  final String postId;
  final PostRepository _posts;
  final WalletRepository _wallet;
  final SessionCubit _session;

  static const suggestions = [10.0, 20.0, 50.0, 100.0];

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    final post = await _posts.getById(postId);
    emit(state.copyWith(status: ViewStatus.success, post: post));
  }

  void setAmount(double value) => emit(state.copyWith(amount: value, error: null));

  Future<void> confirm() async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      final (user, post) = await _wallet.donate(userId: _session.user.id, postId: postId, amount: state.amount);
      _session.updateUser(user);
      emit(state.copyWith(submitting: false, done: true, post: post));
    } on AppException catch (e) {
      emit(state.copyWith(submitting: false, error: e.message));
    }
  }
}
