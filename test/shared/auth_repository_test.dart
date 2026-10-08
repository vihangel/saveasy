import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_database.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/data/models/models.dart';
import 'package:saveeasy2026/shared/data/repositories/repositories.dart';

import '../helpers/test_database.dart';

void main() {
  late AuthRepository auth;
  late MockDatabase db;

  setUp(() async {
    final (database, storage) = await createTestDatabase();
    db = database;
    auth = MockAuthRepository(db, storage);
  });

  const address = Address(cep: '78005000', street: 'Av. Getúlio Vargas, 100', state: 'MT', city: 'Cuiabá');

  test('login com a conta demo salva a sessão', () async {
    final user = await auth.login(MockSeed.demoEmail, MockSeed.demoPassword);
    expect(user.id, MockSeed.demoUserId);
    expect((await auth.restoreSession())?.id, MockSeed.demoUserId);
  });

  test('login com senha errada lança AppException', () {
    expect(auth.login(MockSeed.demoEmail, 'errada'), throwsA(isA<AppException>()));
  });

  test('cadastro: conta → código → completar perfil', () async {
    final result = await auth.signUp(email: 'nova@ong.org', password: 'segredo1');
    expect(result.needsConfirmation, isTrue);

    expect(auth.verifySignUpCode('nova@ong.org', '000000'), throwsA(isA<AppException>()));
    final user = await auth.verifySignUpCode('nova@ong.org', MockSeed.verificationCode);
    expect(user.onboardingCompleted, isFalse);

    final completed = await auth.completeProfile(
      const ProfileCompletion(
        accountType: AccountType.community,
        name: 'ONG Nova',
        username: 'ongnova',
        pronouns: '',
        address: address,
      ),
    );
    expect(completed.onboardingCompleted, isTrue);
    expect(completed.city, 'Cuiabá');
    expect((await auth.login('nova@ong.org', 'segredo1')).username, 'ongnova');
  });

  test('não deixa cadastrar e-mail repetido nem usar @ ocupado', () async {
    expect(auth.signUp(email: MockSeed.demoEmail, password: '123456'), throwsA(isA<AppException>()));
    await auth.signUp(email: 'x@teste.com', password: '123456');
    await auth.verifySignUpCode('x@teste.com', MockSeed.verificationCode);
    expect(await auth.isUsernameAvailable('alexandre.a'), isFalse);
    expect(await auth.isUsernameAvailable('livre.123'), isTrue);
    expect(await auth.isUsernameAvailable('ab'), isFalse);
  });

  test('recuperação de senha troca a senha com o código correto', () async {
    await auth.sendRecoveryCode(MockSeed.demoEmail);
    await auth.verifyRecoveryCode(MockSeed.demoEmail, MockSeed.verificationCode);
    await auth.resetPassword(MockSeed.demoEmail, 'novasenha');
    expect((await auth.login(MockSeed.demoEmail, 'novasenha')).id, MockSeed.demoUserId);
  });

  test('excluir conta remove o usuário e a sessão', () async {
    await auth.login(MockSeed.demoEmail, MockSeed.demoPassword);
    await auth.deleteAccount();
    expect(await auth.restoreSession(), isNull);
    expect(auth.login(MockSeed.demoEmail, MockSeed.demoPassword), throwsA(isA<AppException>()));
  });

  test('dados alterados sobrevivem a um novo load (persistência local)', () async {
    await auth.signUp(email: 'persistido@teste.com', password: '123456');
    await db.load();
    expect(db.users.any((u) => u.email == 'persistido@teste.com'), isTrue);
  });
}
