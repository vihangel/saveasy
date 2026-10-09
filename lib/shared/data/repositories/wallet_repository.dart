import '../models/models.dart';

/// Moedas, pagamentos (Pix/cartão via gateway; sandbox nos testes), doações,
/// inscrições e painel financeiro. Implementações: [MockWalletRepository] e
/// [SupabaseWalletRepository].
abstract interface class WalletRepository {
  Future<List<CoinPackage>> packages();

  /// Extrato: moedas (livro-razão) e pagamentos em R$.
  Future<List<WalletTransaction>> history();

  /// Cria a cobrança. O valor é calculado no servidor a partir do [intent].
  Future<Payment> createPayment(PaymentIntent intent);

  Future<Payment> paymentStatus(String paymentId);

  /// Ambiente de testes: simula o Pix pago e devolve o usuário atualizado.
  Future<(Payment, AppUser)> confirmSandboxPayment(String paymentId, {required String userId});

  /// Doação com moedas: o fundo de doações paga o valor em R$ à campanha.
  Future<(AppUser, Post)> donateCoins({required String userId, required String postId, required int coins});

  Future<AppUser> sendCoins({
    required String userId,
    required String targetId,
    required int coins,
    String message = '',
  });

  Future<DonationFund> fund();

  Future<CommunityPlans> communityPlans(String communityId);

  Future<CommunityPlans> cancelSubscription(String communityId);

  Future<FinanceSummary> finance();

  Future<FinanceSummary> requestPayout({required double amount, required String pixKey});
}
