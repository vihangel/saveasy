import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/features/auth/onboarding/onboarding_cubit.dart';
import 'package:saveeasy2026/features/auth/sign_up/sign_up_cubit.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/data/models/models.dart';
import 'package:saveeasy2026/shared/data/repositories/repositories.dart';
import 'package:saveeasy2026/shared/notifiers/session_cubit.dart';
import 'package:saveeasy2026/shared/utils/view_status.dart';

import '../helpers/test_database.dart';

void main() {
  late AuthRepository auth;
  late SessionCubit session;

  setUp(() async {
    final (db, storage) = await createTestDatabase();
    auth = MockAuthRepository(db, storage);
    session = SessionCubit(auth);
  });

  tearDown(() => session.close());

  blocTest<SignUpCubit, SignUpState>(
    'não avança sem aceitar os termos',
    build: () => SignUpCubit(auth, session),
    act: (cubit) => cubit.submit(email: 'a@b.com', password: '123456'),
    expect: () => [isA<SignUpState>().having((s) => s.status, 'status', ViewStatus.failure)],
  );

  blocTest<SignUpCubit, SignUpState>(
    'recusa e-mail já cadastrado',
    build: () => SignUpCubit(auth, session),
    act: (cubit) {
      cubit.toggleTerms(true);
      return cubit.submit(email: MockSeed.demoEmail, password: '123456');
    },
    skip: 2,
    expect: () => [
      isA<SignUpState>()
          .having((s) => s.status, 'status', ViewStatus.failure)
          .having((s) => s.awaitingCode, 'awaitingCode', false),
    ],
  );

  test('conta criada → código → sessão aberta com perfil incompleto', () async {
    final cubit = SignUpCubit(auth, session)..toggleTerms(true);
    await cubit.submit(email: 'novo@teste.com', password: '123456');
    expect(cubit.state.awaitingCode, isTrue);

    await cubit.verify('123');
    expect(cubit.state.status, ViewStatus.failure);

    await cubit.verify(MockSeed.verificationCode);
    final user = session.state.userOrNull;
    expect(user, isNotNull);
    expect(user!.onboardingCompleted, isFalse);
    await cubit.close();
  });

  test('onboarding completo marca o perfil como pronto', () async {
    final signUp = SignUpCubit(auth, session)..toggleTerms(true);
    await signUp.submit(email: 'novo@teste.com', password: '123456');
    await signUp.verify(MockSeed.verificationCode);

    final cubit = OnboardingCubit(auth, session)
      ..selectAccountType(AccountType.influencer)
      ..confirmAccountType();
    await cubit.submitProfile(name: 'Nova Pessoa', username: 'novapessoa');
    expect(cubit.state.step, OnboardingStep.address);
    await cubit.submitAddress(const Address(cep: '78005000', street: 'Rua B, 10', state: 'MT', city: 'Cuiabá'));

    final user = session.state.userOrNull!;
    expect(user.onboardingCompleted, isTrue);
    expect(user.accountType, AccountType.influencer);
    expect(user.username, 'novapessoa');
    await Future.wait([signUp.close(), cubit.close()]);
  });
}
