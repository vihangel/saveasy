import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/utils/view_status.dart';

part 'wallet_cubit.freezed.dart';
part 'wallet_state.dart';

/// Carteira: moedas, pacotes (pagos com Pix pelo checkout) e extrato.
class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._wallet, this._session) : super(const WalletState());

  final WalletRepository _wallet;
  final SessionCubit _session;

  Future<void> load() async {
    emit(state.copyWith(status: state.history.isEmpty ? ViewStatus.loading : state.status));
    try {
      final (history, packages) = await (_wallet.history(), _wallet.packages()).wait;
      emit(state.copyWith(status: ViewStatus.success, history: history, packages: packages));
    } on ParallelWaitError {
      emit(state.copyWith(status: ViewStatus.failure));
    }
  }

  /// Checkout confirmou a compra do pacote.
  Future<void> purchased(CoinPackage package, AppUser user) async {
    _session.updateUser(user);
    emit(state.copyWith(message: '+${Formatters.number(package.coins)} moedas na sua conta!', error: null));
    await load();
  }
}
