import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_database.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/data/repositories/repositories.dart';

import '../helpers/test_database.dart';

void main() {
  late MockDatabase db;
  late WalletRepository wallet;

  setUp(() async {
    (db, _) = await createTestDatabase();
    wallet = WalletRepository(db);
  });

  test('doar debita o saldo, soma na campanha e dá recompensas', () async {
    final before = db.userById(MockSeed.demoUserId);
    final post = db.posts.firstWhere((p) => p.id == 'p_escola');

    final (user, updatedPost) = await wallet.donate(userId: before.id, postId: post.id, amount: 50);

    expect(user.balance, before.balance - 50);
    expect(user.coins, before.coins + post.rewardCoins);
    expect(user.xp, before.xp + post.rewardXp);
    expect(updatedPost.raisedAmount, post.raisedAmount + 50);
  });

  test('não permite doar mais que o saldo', () {
    expect(wallet.donate(userId: MockSeed.demoUserId, postId: 'p_escola', amount: 1e6), throwsA(isA<AppException>()));
  });

  test('enviar moedas transfere entre usuários', () async {
    final target = db.userById('u_whinderson');
    final user = await wallet.sendCoins(userId: MockSeed.demoUserId, targetId: target.id, coins: 100);
    expect(user.coins, 5000 - 100);
    expect(db.userById(target.id).coins, target.coins + 100);
  });
}
