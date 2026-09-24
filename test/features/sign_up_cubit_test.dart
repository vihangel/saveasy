import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/features/auth/sign_up/sign_up_cubit.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/data/models/models.dart';
import 'package:saveeasy2026/shared/data/repositories/repositories.dart';
import 'package:saveeasy2026/shared/utils/view_status.dart';

import '../helpers/test_database.dart';

void main() {
  late AuthRepository auth;

  setUp(() async {
    final (db, storage) = await createTestDatabase();
    auth = AuthRepository(db, storage);
  });

  blocTest<SignUpCubit, SignUpState>(
    'não avança sem aceitar os termos',
    build: () => SignUpCubit(auth),
    act: (cubit) => cubit.submitCredentials(email: 'a@b.com', password: '123456'),
    expect: () => [isA<SignUpState>().having((s) => s.status, 'status', ViewStatus.failure)],
  );

  blocTest<SignUpCubit, SignUpState>(
    'recusa e-mail já cadastrado',
    build: () => SignUpCubit(auth),
    act: (cubit) {
      cubit.toggleTerms(true);
      return cubit.submitCredentials(email: MockSeed.demoEmail, password: '123456');
    },
    skip: 2,
    expect: () => [
      isA<SignUpState>()
          .having((s) => s.status, 'status', ViewStatus.failure)
          .having((s) => s.step, 'step', SignUpStep.accountType),
    ],
  );

  blocTest<SignUpCubit, SignUpState>(
    'fluxo completo chega em done',
    build: () => SignUpCubit(auth),
    act: (cubit) async {
      cubit.selectAccountType(AccountType.influencer);
      cubit.confirmAccountType();
      cubit.toggleTerms(true);
      await cubit.submitCredentials(email: 'novo@teste.com', password: '123456');
      await cubit.submitProfile(name: 'Nova Pessoa', username: 'novapessoa');
      await cubit.submitAddress(const Address(cep: '01001000', street: 'Rua B', state: 'SP', city: 'São Paulo'));
    },
    verify: (cubit) {
      expect(cubit.state.step, SignUpStep.done);
      expect(cubit.state.accountType, AccountType.influencer);
    },
  );
}
