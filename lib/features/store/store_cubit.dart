import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/view_status.dart';

part 'store_cubit.freezed.dart';
part 'store_state.dart';

/// "Lojas da Comunidade": vitrine com busca. Compra e detalhe ficam em
/// [ProductPage] (checkout Pix).
class StoreCubit extends Cubit<StoreState> {
  StoreCubit(this._store) : super(const StoreState());

  final StoreRepository _store;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(status: state.products.isEmpty ? ViewStatus.loading : state.status));
    try {
      emit(
        state.copyWith(
          status: ViewStatus.success,
          products: await _store.products(query: state.query),
        ),
      );
    } on AppException {
      emit(state.copyWith(status: ViewStatus.failure));
    }
  }

  void search(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
