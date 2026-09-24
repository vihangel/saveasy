import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

part 'session_cubit.freezed.dart';
part 'session_state.dart';

/// Estado global de autenticação e do usuário logado.
///
/// As features que alteram o usuário (doar, resgatar, editar perfil...)
/// chamam [updateUser] para que saldo, moedas e nível fiquem sincronizados
/// em todas as telas.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._auth) : super(const SessionState.unknown());

  final AuthRepository _auth;

  AppUser get user => (state as SessionAuthenticated).user;

  Future<void> restore() async {
    final user = await _auth.restoreSession();
    emit(
      user == null
          ? SessionState.unauthenticated(onboardingSeen: _auth.hasSeenOnboarding)
          : SessionState.authenticated(user),
    );
  }

  Future<void> completeOnboarding() async {
    await _auth.markOnboardingSeen();
    emit(const SessionState.unauthenticated(onboardingSeen: true));
  }

  void signedIn(AppUser user) => emit(SessionState.authenticated(user));

  void updateUser(AppUser user) {
    if (state is SessionAuthenticated) emit(SessionState.authenticated(user));
  }

  Future<void> logout() async {
    await _auth.logout();
    emit(const SessionState.unauthenticated(onboardingSeen: true));
  }
}
