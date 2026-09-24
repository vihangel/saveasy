part of 'forgot_password_cubit.dart';

enum ForgotPasswordStep { email, code, newPassword, done }

@freezed
abstract class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState({
    @Default(ForgotPasswordStep.email) ForgotPasswordStep step,
    @Default('') String email,
    @Default(ViewStatus.initial) ViewStatus status,
    String? error,
  }) = _ForgotPasswordState;
}
