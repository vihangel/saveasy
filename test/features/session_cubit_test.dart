import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/data/repositories/repositories.dart';
import 'package:saveeasy2026/shared/notifiers/session_cubit.dart';

import '../helpers/test_database.dart';

void main() {
  late AuthRepository auth;

  setUp(() async {
    final (db, storage) = await createTestDatabase();
    auth = AuthRepository(db, storage);
  });

  blocTest<SessionCubit, SessionState>(
    'sem sessão salva e sem onboarding vai para não autenticado',
    build: () => SessionCubit(auth),
    act: (cubit) => cubit.restore(),
    expect: () => [const SessionState.unauthenticated(onboardingSeen: false)],
  );

  blocTest<SessionCubit, SessionState>(
    'restaura a sessão depois do login',
    setUp: () => auth.login(MockSeed.demoEmail, MockSeed.demoPassword),
    build: () => SessionCubit(auth),
    act: (cubit) => cubit.restore(),
    expect: () => [isA<SessionAuthenticated>()],
  );
}
