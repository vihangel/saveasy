part of 'sign_up_cubit.dart';

@freezed
abstract class SignUpState with _$SignUpState {
  const factory SignUpState({
    @Default('') String email,
    @Default(false) bool acceptedTerms,

    /// true depois de criar a conta, quando falta o código do e-mail.
    @Default(false) bool awaitingCode,
    @Default(ViewStatus.initial) ViewStatus status,
    String? error,
    String? message,
  }) = _SignUpState;
}
