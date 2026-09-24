part of 'login_cubit.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({@Default(ViewStatus.initial) ViewStatus status, String? error}) = _LoginState;
}
