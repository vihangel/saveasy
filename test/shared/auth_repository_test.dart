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
    auth = AuthRepository(db, storage);
  });

  test('login com a conta demo salva a sessão', () async {
    final user = await auth.login(MockSeed.demoEmail, MockSeed.demoPassword);
    expect(user.id, MockSeed.demoUserId);
    expect((await auth.restoreSession())?.id, MockSeed.demoUserId);
  });

  test('login com senha errada lança AppException', () {
    expect(auth.login(MockSeed.demoEmail, 'errada'), throwsA(isA<AppException>()));
  });

  test('cadastro cria usuário que consegue fazer login', () async {
    await auth.register(
      const SignUpData(
        accountType: AccountType.community,
        email: 'nova@ong.org',
        password: 'segredo',
        name: 'ONG Nova',
        username: '@ongnova',
        pronouns: 'Elu/delu',
        birthDate: null,
        address: Address(cep: '01001000', street: 'Praça da Sé', state: 'SP', city: 'São Paulo'),
        emailNews: true,
      ),
    );
    final user = await auth.login('nova@ong.org', 'segredo');
    expect(user.username, 'ongnova');
    expect(user.accountType, AccountType.community);
  });

  test('recuperação de senha troca a senha com o código correto', () async {
    await auth.sendRecoveryCode(MockSeed.demoEmail);
    await auth.verifyCode(MockSeed.demoEmail, MockSeed.verificationCode);
    await auth.resetPassword(MockSeed.demoEmail, 'novasenha');
    expect((await auth.login(MockSeed.demoEmail, 'novasenha')).id, MockSeed.demoUserId);
  });

  test('dados alterados sobrevivem a um novo load (persistência local)', () async {
    await auth.register(
      const SignUpData(
        accountType: AccountType.personal,
        email: 'persistido@teste.com',
        password: '123456',
        name: 'Persistido',
        username: 'persistido',
        pronouns: 'Ele/dele',
        birthDate: null,
        address: Address(cep: '01001000', street: 'Rua A', state: 'SP', city: 'São Paulo'),
        emailNews: false,
      ),
    );
    await db.load();
    expect(db.users.any((u) => u.email == 'persistido@teste.com'), isTrue);
  });
}
