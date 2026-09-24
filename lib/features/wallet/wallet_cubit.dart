import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/utils/view_status.dart';

part 'wallet_cubit.freezed.dart';
part 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._wallet, this._session) : super(const WalletState());

  final WalletRepository _wallet;
  final SessionCubit _session;

  Future<void> load() async {
    emit(state.copyWith(status: state.history.isEmpty ? ViewStatus.loading : state.status));
    emit(state.copyWith(status: ViewStatus.success, history: await _wallet.history()));
  }

  Future<void> buy(CoinPackage package) async {
    emit(state.copyWith(buying: package, error: null, message: null));
    try {
      final user = await _wallet.buyCoins(userId: _session.user.id, package: package);
      _session.updateUser(user);
      emit(state.copyWith(buying: null, message: '+${Formatters.number(package.coins)} moedas na sua conta!'));
      await load();
    } on AppException catch (e) {
      emit(state.copyWith(buying: null, error: e.message));
    }
  }

  /// Adiciona saldo fictício (não existe gateway de pagamento no protótipo).
  Future<void> addFunds() async {
    final user = await _wallet.addFunds(userId: _session.user.id, amount: 100);
    _session.updateUser(user);
    emit(state.copyWith(message: 'R\$ 100,00 adicionados (simulado).'));
  }
}
