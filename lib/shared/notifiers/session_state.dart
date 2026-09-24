part of 'session_cubit.dart';

@freezed
sealed class SessionState with _$SessionState {
  const SessionState._();

  /// App acabou de abrir e ainda não verificou a sessão salva.
  const factory SessionState.unknown() = SessionUnknown;

  const factory SessionState.unauthenticated({required bool onboardingSeen}) = SessionUnauthenticated;

  const factory SessionState.authenticated(AppUser user) = SessionAuthenticated;

  AppUser? get userOrNull => switch (this) {
    SessionAuthenticated(:final user) => user,
    _ => null,
  };
}
