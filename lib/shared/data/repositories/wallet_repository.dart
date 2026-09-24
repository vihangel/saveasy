import '../datasources/mock_database.dart';
import '../models/models.dart';
import 'app_exception.dart';
import 'user_progress.dart';

/// Movimentações de dinheiro (saldo em R$) e moedas do app.
class WalletRepository {
  WalletRepository(this._db);

  final MockDatabase _db;

  static const packages = [
    CoinPackage(coins: 1000, price: 4.99),
    CoinPackage(coins: 2500, price: 11.99),
    CoinPackage(coins: 5000, price: 24.90),
  ];

  Future<List<WalletTransaction>> history() async {
    await _db.delay();
    return [..._db.transactions]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<AppUser> buyCoins({required String userId, required CoinPackage package}) async {
    await _db.delay();
    final user = _db.userById(userId);
    _ensureBalance(user, package.price);
    final updated = user.copyWith(balance: user.balance - package.price, coins: user.coins + package.coins);
    await _commit(
      updated,
      WalletTransaction(
        id: _db.newId('t'),
        kind: TransactionKind.purchase,
        description: '${package.coins} moedas',
        date: DateTime.now(),
        coins: package.coins,
        money: -package.price,
      ),
    );
    return updated;
  }

  /// Doa dinheiro para uma campanha e aplica as recompensas do post.
  Future<(AppUser, Post)> donate({required String userId, required String postId, required double amount}) async {
    await _db.delay();
    if (amount <= 0) throw const AppException('Informe um valor maior que zero.');
    final user = _db.userById(userId);
    _ensureBalance(user, amount);
    final post = _db.posts.firstWhere((p) => p.id == postId);
    final updatedPost = post.copyWith(raisedAmount: post.raisedAmount + amount);
    await _db.replacePost(updatedPost);
    final updatedUser = user
        .copyWith(balance: user.balance - amount)
        .reward(xp: post.rewardXp, coins: post.rewardCoins);
    await _commit(
      updatedUser,
      WalletTransaction(
        id: _db.newId('t'),
        kind: TransactionKind.donation,
        description: post.title,
        date: DateTime.now(),
        money: -amount,
      ),
    );
    await _progressAchievement('a_donations');
    return (updatedUser, updatedPost);
  }

  /// Envia moedas para o autor de uma publicação.
  Future<AppUser> sendCoins({
    required String userId,
    required String targetId,
    required int coins,
    String message = '',
  }) async {
    await _db.delay();
    final user = _db.userById(userId);
    if (coins <= 0) throw const AppException('Escolha quantas moedas enviar.');
    if (user.coins < coins) throw const AppException('Você não tem moedas suficientes.');
    final target = _db.userById(targetId);
    await _db.replaceUser(target.copyWith(coins: target.coins + coins));
    final updated = user.copyWith(coins: user.coins - coins).reward(xp: coins ~/ 2);
    await _commit(
      updated,
      WalletTransaction(
        id: _db.newId('t'),
        kind: TransactionKind.coinsSent,
        description: 'Para ${target.name}${message.isEmpty ? '' : ' - "$message"'}',
        date: DateTime.now(),
        coins: -coins,
      ),
    );
    return updated;
  }

  Future<AppUser> buyProduct({required String userId, required Product product}) async {
    await _db.delay();
    final user = _db.userById(userId);
    _ensureBalance(user, product.price);
    final updated = user.copyWith(balance: user.balance - product.price).reward(xp: 30, coins: 20);
    await _commit(
      updated,
      WalletTransaction(
        id: _db.newId('t'),
        kind: TransactionKind.store,
        description: '${product.name} - ${product.communityName}',
        date: DateTime.now(),
        money: -product.price,
      ),
    );
    return updated;
  }

  /// Inscrição (assinatura mensal) em uma comunidade.
  Future<AppUser> subscribe({required String userId, required String communityId, required double price}) async {
    await _db.delay();
    final user = _db.userById(userId);
    _ensureBalance(user, price);
    final community = _db.userById(communityId);
    final updated = user
        .copyWith(balance: user.balance - price, subscribedCommunityIds: [...user.subscribedCommunityIds, communityId])
        .reward(xp: 80, coins: 50);
    await _commit(
      updated,
      WalletTransaction(
        id: _db.newId('t'),
        kind: TransactionKind.subscription,
        description: 'Inscrição - ${community.name}',
        date: DateTime.now(),
        money: -price,
      ),
    );
    return updated;
  }

  /// Saldo fictício para testar os fluxos sem gateway de pagamento.
  Future<AppUser> addFunds({required String userId, required double amount}) async {
    await _db.delay();
    final user = _db.userById(userId);
    final updated = user.copyWith(balance: user.balance + amount);
    await _db.replaceUser(updated);
    return updated;
  }

  void _ensureBalance(AppUser user, double amount) {
    if (user.balance < amount) throw const AppException('Saldo insuficiente na carteira.');
  }

  Future<void> _commit(AppUser user, WalletTransaction transaction) async {
    await _db.replaceUser(user);
    _db.transactions = [..._db.transactions, transaction];
    await _db.saveTransactions();
  }

  Future<void> _progressAchievement(String id) async {
    _db.achievements = [for (final a in _db.achievements) a.id == id ? a.copyWith(current: a.current + 1) : a];
    await _db.saveAchievements();
  }
}
