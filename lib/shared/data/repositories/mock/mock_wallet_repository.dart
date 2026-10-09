import '../../datasources/mock_database.dart';
import '../../models/models.dart';
import '../app_exception.dart';
import '../user_progress.dart';
import '../wallet_repository.dart';

/// Carteira local: pagamentos sempre em modo sandbox.
class MockWalletRepository implements WalletRepository {
  MockWalletRepository(this._db);

  final MockDatabase _db;
  final _pending = <String, (Payment, PaymentIntent)>{};

  static const _packages = [
    CoinPackage(id: 'coins_1000', coins: 1000, price: 4.99),
    CoinPackage(id: 'coins_2500', coins: 2500, price: 11.99),
    CoinPackage(id: 'coins_5000', coins: 5000, price: 24.90),
  ];

  @override
  Future<List<CoinPackage>> packages() async => _packages;

  @override
  Future<List<WalletTransaction>> history() async {
    await _db.delay();
    return [..._db.transactions]..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Payment> createPayment(PaymentIntent intent) async {
    await _db.delay();
    final (amount, description) = switch (intent.kind) {
      PaymentKind.donation => ((intent.params['amount']! as num).toDouble(), 'Doação'),
      PaymentKind.coinPackage => (_package(intent).price, '${_package(intent).coins} moedas'),
      PaymentKind.subscription => (9.90, 'Inscrição'),
      PaymentKind.order => (_product(intent).price * ((intent.params['quantity'] as int?) ?? 1), _product(intent).name),
      PaymentKind.adCampaign => (49.90, 'Anúncio'),
    };
    if (amount <= 0) throw const AppException('Informe um valor maior que zero.');
    final payment = Payment(
      id: _db.newId('pay'),
      kind: intent.kind,
      amount: amount,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      description: description,
      pixCode: '00020126SAVEEASY-MOCK',
      sandbox: true,
    );
    _pending[payment.id] = (payment, intent);
    return payment;
  }

  @override
  Future<Payment> paymentStatus(String paymentId) async {
    final entry = _pending[paymentId];
    if (entry == null) throw const AppException('Pagamento não encontrado.');
    return entry.$1;
  }

  @override
  Future<(Payment, AppUser)> confirmSandboxPayment(String paymentId, {required String userId}) async {
    await _db.delay();
    final entry = _pending[paymentId];
    if (entry == null) throw const AppException('Pagamento não encontrado.');
    final (payment, intent) = entry;
    if (payment.status == PaymentStatus.paid) return (payment, _db.userById(userId));
    var user = _db.userById(userId);
    final (kind, coins, xp) = switch (intent.kind) {
      PaymentKind.donation => (TransactionKind.donation, _donationReward(intent).$1, _donationReward(intent).$2),
      PaymentKind.coinPackage => (TransactionKind.purchase, _package(intent).coins, 0),
      PaymentKind.subscription => (TransactionKind.subscription, 50, 80),
      PaymentKind.order => (TransactionKind.store, 20, 30),
      PaymentKind.adCampaign => (TransactionKind.bonus, 0, 0),
    };
    if (intent.kind == PaymentKind.donation) {
      final post = _db.posts.where((p) => p.id == intent.params['postId']).firstOrNull;
      if (post != null) await _db.replacePost(post.copyWith(raisedAmount: post.raisedAmount + payment.amount));
    }
    user = user.reward(coins: coins, xp: xp);
    await _db.replaceUser(user);
    final paid = payment.copyWith(status: PaymentStatus.paid, paidAt: DateTime.now());
    _pending[paymentId] = (paid, intent);
    _db.transactions = [
      ..._db.transactions,
      WalletTransaction(
        id: _db.newId('t'),
        kind: kind,
        description: payment.description,
        date: DateTime.now(),
        coins: intent.kind == PaymentKind.coinPackage ? coins : 0,
        money: -payment.amount,
      ),
    ];
    await _db.saveTransactions();
    return (paid, user);
  }

  @override
  Future<(AppUser, Post)> donateCoins({required String userId, required String postId, required int coins}) async {
    await _db.delay();
    if (coins < 100) throw const AppException('Doe pelo menos 100 moedas.');
    final user = _db.userById(userId);
    if (user.coins < coins) throw const AppException('Você não tem moedas suficientes.');
    final post = _db.posts.firstWhere((p) => p.id == postId);
    final updatedPost = post.copyWith(raisedAmount: post.raisedAmount + coins / 100);
    await _db.replacePost(updatedPost);
    final updatedUser = user.copyWith(coins: user.coins - coins).reward(xp: coins ~/ 20);
    await _db.replaceUser(updatedUser);
    return (updatedUser, updatedPost);
  }

  @override
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
    await _db.replaceUser(updated);
    _db.transactions = [
      ..._db.transactions,
      WalletTransaction(
        id: _db.newId('t'),
        kind: TransactionKind.coinsSent,
        description: 'Para ${target.name}${message.isEmpty ? '' : ' - "$message"'}',
        date: DateTime.now(),
        coins: -coins,
      ),
    ];
    await _db.saveTransactions();
    return updated;
  }

  @override
  Future<DonationFund> fund() async => const DonationFund(balance: 500, received: 500);

  @override
  Future<CommunityPlans> communityPlans(String communityId) async => const CommunityPlans(
    plans: [
      SubscriptionPlan(id: 'mensal', name: 'Mensal', price: 9.90, benefits: 'Apoie todo mês.'),
      SubscriptionPlan(id: 'anual', name: 'Anual', price: 99, months: 12, benefits: '2 meses grátis.'),
    ],
  );

  @override
  Future<CommunityPlans> cancelSubscription(String communityId) => communityPlans(communityId);

  @override
  Future<CommunityPlans> savePlan(SubscriptionPlan plan, {bool active = true}) async {
    if (plan.name.trim().length < 2 || plan.price <= 0) throw const AppException('Informe nome e preço.');
    return communityPlans('');
  }

  @override
  Future<FinanceSummary> finance() async => const FinanceSummary();

  @override
  Future<FinanceSummary> requestPayout({required double amount, required String pixKey}) async =>
      throw const AppException('Repasses só no ambiente com back-end.');

  CoinPackage _package(PaymentIntent intent) => _packages.firstWhere((p) => p.id == intent.params['packageId']);

  Product _product(PaymentIntent intent) => _db.products.firstWhere((p) => p.id == intent.params['productId']);

  (int, int) _donationReward(PaymentIntent intent) {
    final post = _db.posts.where((p) => p.id == intent.params['postId']).firstOrNull;
    return (post?.rewardCoins ?? 0, post?.rewardXp ?? 0);
  }
}
