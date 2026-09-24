part of 'sign_up_cubit.dart';

enum SignUpStep { accountType, credentials, profile, address, done }

@freezed
abstract class SignUpState with _$SignUpState {
  const SignUpState._();

  const factory SignUpState({
    @Default(SignUpStep.accountType) SignUpStep step,
    @Default(AccountType.personal) AccountType accountType,
    @Default('') String email,
    @Default('') String password,
    @Default(false) bool acceptedTerms,
    @Default(false) bool emailNews,
    @Default('') String name,
    @Default('Ele/dele') String pronouns,
    @Default('') String username,
    DateTime? birthDate,
    String? avatarUrl,
    @Default(ViewStatus.initial) ViewStatus status,
    String? error,
  }) = _SignUpState;
}
