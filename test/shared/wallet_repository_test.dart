import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_database.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/data/models/models.dart';
import 'package:saveeasy2026/shared/data/repositories/repositories.dart';

import '../helpers/test_database.dart';

void main() {
  late MockDatabase db;
  late WalletRepository wallet;

  setUp(() async {
    (db, _) = await createTestDatabase();
    wallet = MockWalletRepository(db);
  });

  test('doação por Pix (sandbox) soma na campanha e dá recompensas uma vez', () async {
    final before = db.userById(MockSeed.demoUserId);
    final post = db.posts.firstWhere((p) => p.id == 'p_escola');

    final payment = await wallet.createPayment(PaymentIntent.donation(postId: post.id, amount: 50));
    expect(payment.status, PaymentStatus.pending);
    expect(payment.sandbox, isTrue);

    final (paid, user) = await wallet.confirmSandboxPayment(payment.id, userId: before.id);
    expect(paid.status, PaymentStatus.paid);
    expect(user.coins, before.coins + post.rewardCoins);
    expect(db.posts.firstWhere((p) => p.id == post.id).raisedAmount, post.raisedAmount + 50);

    // Confirmar de novo não credita outra vez.
    final (_, again) = await wallet.confirmSandboxPayment(payment.id, userId: before.id);
    expect(again.coins, user.coins);
  });

  test('pacote de moedas credita as moedas do pacote', () async {
    final before = db.userById(MockSeed.demoUserId);
    final package = (await wallet.packages()).first;
    final payment = await wallet.createPayment(PaymentIntent.coins(package));
    final (_, user) = await wallet.confirmSandboxPayment(payment.id, userId: before.id);
    expect(user.coins, before.coins + package.coins);
  });

  test('doar moedas debita as moedas e soma R\$ na campanha', () async {
    final before = db.userById(MockSeed.demoUserId);
    final post = db.posts.firstWhere((p) => p.id == 'p_escola');
    final (user, updated) = await wallet.donateCoins(userId: before.id, postId: post.id, coins: 500);
    expect(user.coins, before.coins - 500);
    expect(updated.raisedAmount, post.raisedAmount + 5);
    expect(wallet.donateCoins(userId: before.id, postId: post.id, coins: 50), throwsA(isA<AppException>()));
  });

  test('enviar moedas transfere entre usuários', () async {
    final target = db.userById('u_whinderson');
    final user = await wallet.sendCoins(userId: MockSeed.demoUserId, targetId: target.id, coins: 100);
    expect(user.coins, 5000 - 100);
    expect(db.userById(target.id).coins, target.coins + 100);
  });
}
