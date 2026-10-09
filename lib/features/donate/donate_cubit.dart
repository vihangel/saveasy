import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'donate_cubit.freezed.dart';
part 'donate_state.dart';

/// Fluxo Doar 1 → 2 → 3/4: escolher valor, pagar e ver as recompensas.
/// O pagamento em dinheiro abre o checkout (Pix) na tela; aqui só entra o
/// resultado.
class DonateCubit extends Cubit<DonateState> {
  DonateCubit(this.postId, this._posts, this._wallet, this._session) : super(const DonateState());

  final String postId;
  final PostRepository _posts;
  final WalletRepository _wallet;
  final SessionCubit _session;

  static const suggestions = [10.0, 20.0, 50.0, 100.0];
  static const coinSuggestions = [100, 500, 1000, 2000];

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    try {
      final (post, fund) = await (_posts.getById(postId), _wallet.fund()).wait;
      emit(state.copyWith(status: ViewStatus.success, post: post, fund: fund));
    } on ParallelWaitError {
      emit(state.copyWith(status: ViewStatus.failure));
    }
  }

  void setMode(DonateMode mode) => emit(state.copyWith(mode: mode, error: null));

  void setAmount(double value) => emit(state.copyWith(amount: value, error: null));

  void setCoins(int value) => emit(state.copyWith(coins: value, error: null));

  PaymentIntent get intent => PaymentIntent.donation(postId: postId, amount: state.amount);

  /// Chamado pela tela quando o checkout confirma o pagamento.
  Future<void> paid(AppUser user) async {
    _session.updateUser(user);
    final post = await _posts.getById(postId);
    emit(state.copyWith(done: true, post: post));
  }

  Future<void> donateCoins() async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      final (user, post) = await _wallet.donateCoins(userId: _session.user.id, postId: postId, coins: state.coins);
      _session.updateUser(user);
      emit(state.copyWith(submitting: false, done: true, post: post));
    } on AppException catch (e) {
      emit(state.copyWith(submitting: false, error: e.message));
    }
  }
}
