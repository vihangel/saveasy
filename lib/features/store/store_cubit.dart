import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'store_cubit.freezed.dart';
part 'store_state.dart';

/// "Lojas da Comunidade" e detalhe de produto (Loja 3 / Loja 5).
class StoreCubit extends Cubit<StoreState> {
  StoreCubit(this._store, this._wallet, this._session) : super(const StoreState());

  final StoreRepository _store;
  final WalletRepository _wallet;
  final SessionCubit _session;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(status: state.products.isEmpty ? ViewStatus.loading : state.status));
    emit(
      state.copyWith(
        status: ViewStatus.success,
        products: await _store.products(query: state.query),
      ),
    );
  }

  void search(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> buy(Product product) async {
    emit(state.copyWith(buyingId: product.id, error: null, message: null));
    try {
      final user = await _wallet.buyProduct(userId: _session.user.id, product: product);
      _session.updateUser(user);
      emit(state.copyWith(buyingId: null, message: 'Compra realizada! A comunidade agradece 💛'));
    } on AppException catch (e) {
      emit(state.copyWith(buyingId: null, error: e.message));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
