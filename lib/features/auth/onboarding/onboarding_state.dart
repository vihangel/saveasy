part of 'onboarding_cubit.dart';

enum OnboardingStep { accountType, profile, address, done }

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(OnboardingStep.accountType) OnboardingStep step,
    @Default(AccountType.personal) AccountType accountType,
    @Default('') String name,
    @Default('') String username,
    @Default('Ele/dele') String pronouns,
    DateTime? birthDate,
    String? avatarUrl,
    @Default(false) bool emailNews,
    @Default(ViewStatus.initial) ViewStatus status,
    String? error,
  }) = _OnboardingState;
}
