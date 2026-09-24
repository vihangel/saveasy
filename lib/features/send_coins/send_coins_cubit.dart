import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'send_coins_cubit.freezed.dart';
part 'send_coins_state.dart';

/// Enviar Moedas → Enviar Moedas 1 (mensagem) → Enviar Moedas 2 (sucesso).
class SendCoinsCubit extends Cubit<SendCoinsState> {
  SendCoinsCubit({
    required this.targetId,
    required this.postId,
    required this._users,
    required this._posts,
    required this._wallet,
    required this._session,
  }) : super(const SendCoinsState());

  final String targetId;
  final String? postId;
  final UserRepository _users;
  final PostRepository _posts;
  final WalletRepository _wallet;
  final SessionCubit _session;

  static const options = [10, 50, 100, 250, 500];

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    final target = await _users.getById(targetId);
    final post = postId == null ? null : await _posts.getById(postId!);
    emit(state.copyWith(status: ViewStatus.success, target: target, post: post));
  }

  void selectCoins(int value) => emit(state.copyWith(coins: value, error: null));

  void setMessage(String value) => emit(state.copyWith(message: value));

  Future<void> send() async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      final user = await _wallet.sendCoins(
        userId: _session.user.id,
        targetId: targetId,
        coins: state.coins,
        message: state.message.trim(),
      );
      _session.updateUser(user);
      emit(state.copyWith(submitting: false, done: true));
    } on AppException catch (e) {
      emit(state.copyWith(submitting: false, error: e.message));
    }
  }
}
