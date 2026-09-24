import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/data/repositories/repositories.dart';
import '../../../shared/notifiers/session_cubit.dart';
import '../../../shared/utils/view_status.dart';

part 'login_cubit.freezed.dart';
part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._auth, this._session) : super(const LoginState());

  final AuthRepository _auth;
  final SessionCubit _session;

  Future<void> login(String email, String password) => _run(() => _auth.login(email, password).then(_session.signedIn));

  Future<void> loginWithProvider(String provider) =>
      _run(() => _auth.loginWithProvider(provider).then(_session.signedIn));

  Future<void> _run(Future<void> Function() action) async {
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    try {
      await action();
      emit(state.copyWith(status: ViewStatus.success));
    } on AppException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }
}
