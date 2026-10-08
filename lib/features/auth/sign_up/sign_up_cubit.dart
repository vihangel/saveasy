import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/data/repositories/repositories.dart';
import '../../../shared/notifiers/session_cubit.dart';
import '../../../shared/utils/view_status.dart';

part 'sign_up_cubit.freezed.dart';
part 'sign_up_state.dart';

/// Cadastro (Sign Up Page do protótipo): e-mail e senha → código do e-mail.
/// Depois disso a pessoa já está logada e completa o perfil no onboarding.
class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this._auth, this._session) : super(const SignUpState());

  final AuthRepository _auth;
  final SessionCubit _session;

  void toggleTerms(bool value) => emit(state.copyWith(acceptedTerms: value));

  Future<void> submit({required String email, required String password}) async {
    if (!state.acceptedTerms) {
      return emit(state.copyWith(status: ViewStatus.failure, error: 'Você precisa aceitar os termos.'));
    }
    emit(state.copyWith(status: ViewStatus.loading, error: null, email: email.trim()));
    try {
      final result = await _auth.signUp(email: email, password: password);
      if (result.user != null) {
        _session.signedIn(result.user!);
        return emit(state.copyWith(status: ViewStatus.success));
      }
      emit(state.copyWith(status: ViewStatus.success, awaitingCode: true));
    } on AppException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }

  Future<void> verify(String code) async {
    if (code.trim().length != 6) {
      return emit(state.copyWith(status: ViewStatus.failure, error: 'Digite os 6 números do código.'));
    }
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    try {
      final user = await _auth.verifySignUpCode(state.email, code);
      emit(state.copyWith(status: ViewStatus.success));
      _session.signedIn(user);
    } on AppException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }

  Future<void> resend() async {
    try {
      await _auth.resendSignUpCode(state.email);
      emit(state.copyWith(message: 'Enviamos um novo código para ${state.email}.', error: null));
    } on AppException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }
}
