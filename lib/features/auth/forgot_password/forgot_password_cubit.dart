import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/data/repositories/repositories.dart';
import '../../../shared/utils/view_status.dart';

part 'forgot_password_cubit.freezed.dart';
part 'forgot_password_state.dart';

/// Fluxo "Rec. Senha 1 → Validar código → Rec. Senha 2".
/// Uma única instância é compartilhada pelas três telas.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._auth) : super(const ForgotPasswordState());

  final AuthRepository _auth;

  Future<void> sendCode(String email) =>
      _run(() => _auth.sendRecoveryCode(email), next: ForgotPasswordStep.code, email: email.trim());

  Future<void> verifyCode(String code) =>
      _run(() => _auth.verifyCode(state.email, code), next: ForgotPasswordStep.newPassword);

  Future<void> resetPassword(String password) =>
      _run(() => _auth.resetPassword(state.email, password), next: ForgotPasswordStep.done);

  Future<void> _run(Future<void> Function() action, {required ForgotPasswordStep next, String? email}) async {
    emit(state.copyWith(status: ViewStatus.loading, error: null, email: email ?? state.email));
    try {
      await action();
      emit(state.copyWith(status: ViewStatus.success, step: next));
    } on AppException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }
}
