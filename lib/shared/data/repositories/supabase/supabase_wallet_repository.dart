import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../app_exception.dart';
import '../wallet_repository.dart';
import 'supabase_guard.dart';

/// Moedas, pagamentos, doações, inscrições e finanças
/// (supabase/migrations/*_payments_store.sql).
class SupabaseWalletRepository implements WalletRepository {
  SupabaseWalletRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CoinPackage>> packages() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('coin_packages_list');
    return list.map((p) => CoinPackage.fromJson(p as Map<String, dynamic>)).toList();
  });

  /// Extrato de moedas + pagamentos em R$.
  @override
  Future<List<WalletTransaction>> history() => supabaseGuard(() async {
    final (rows, payments) = await (
      _client
          .from('coin_ledger')
          .select('id, amount, reason, note, created_at, counterpart:profiles!coin_ledger_counterpart_id_fkey(name)')
          .order('created_at', ascending: false)
          .limit(50),
      _client.rpc<List<dynamic>>('my_payments'),
    ).wait;
    return [...rows.map(_fromLedger), ...payments.map((p) => _fromPayment(Payment.fromJson(p as Map<String, dynamic>)))]
      ..sort((a, b) => b.date.compareTo(a.date));
  });

  @override
  Future<Payment> createPayment(PaymentIntent intent) => supabaseGuard(() async {
    final json = intent.kind == PaymentKind.adCampaign
        ? await _client.rpc<Map<String, dynamic>>(
            'ad_campaign_payment',
            params: {'p_campaign_id': int.parse(intent.params['campaignId']! as String)},
          )
        : await _client.rpc<Map<String, dynamic>>(
            'create_payment',
            params: {'p_kind': _kind(intent.kind), 'p': _params(intent)},
          );
    final payment = Payment.fromJson(json);
    if (payment.sandbox) return payment;
    // Produção: a Edge Function gera o Pix real no gateway.
    final response = await _client.functions.invoke('payment-pix', body: {'paymentId': payment.id});
    final data = response.data as Map<String, dynamic>;
    if (data['error'] != null) throw AppException(data['error'] as String);
    return payment.copyWith(pixCode: data['pixCode'] as String?);
  });

  @override
  Future<Payment> paymentStatus(String paymentId) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>?>('payment_status', params: {'p_payment_id': paymentId});
    if (json == null) throw const AppException('Pagamento não encontrado.');
    return Payment.fromJson(json);
  });

  @override
  Future<(Payment, AppUser)> confirmSandboxPayment(String paymentId, {required String userId}) =>
      supabaseGuard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'confirm_sandbox_payment',
          params: {'p_payment_id': paymentId},
        );
        return (
          Payment.fromJson(json['payment'] as Map<String, dynamic>),
          AppUser.fromJson(json['me'] as Map<String, dynamic>),
        );
      });

  @override
  Future<(AppUser, Post)> donateCoins({required String userId, required String postId, required int coins}) =>
      supabaseGuard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'donate_coins',
          params: {'p_post_id': int.parse(postId), 'p_coins': coins},
        );
        return (
          AppUser.fromJson(json['me'] as Map<String, dynamic>),
          Post.fromJson(json['post'] as Map<String, dynamic>),
        );
      });

  @override
  Future<AppUser> sendCoins({
    required String userId,
    required String targetId,
    required int coins,
    String message = '',
  }) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'send_coins',
      params: {'p_to': targetId, 'p_amount': coins, 'p_message': message},
    );
    return AppUser.fromJson(json);
  });

  @override
  Future<DonationFund> fund() => supabaseGuard(() async {
    return DonationFund.fromJson(await _client.rpc<Map<String, dynamic>>('donation_fund'));
  });

  @override
  Future<CommunityPlans> communityPlans(String communityId) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('community_plans', params: {'p_community_id': communityId});
    return CommunityPlans.fromJson(json);
  });

  @override
  Future<CommunityPlans> cancelSubscription(String communityId) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'cancel_subscription',
      params: {'p_community_id': communityId},
    );
    return CommunityPlans.fromJson(json);
  });

  @override
  Future<FinanceSummary> finance() => supabaseGuard(() async {
    return FinanceSummary.fromJson(await _client.rpc<Map<String, dynamic>>('my_finance'));
  });

  @override
  Future<FinanceSummary> requestPayout({required double amount, required String pixKey}) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'request_payout',
      params: {'p_amount': amount, 'p_pix_key': pixKey.trim()},
    );
    return FinanceSummary.fromJson(json);
  });

  Map<String, Object?> _params(PaymentIntent intent) => {
    for (final e in intent.params.entries)
      e.key: e.key.endsWith('Id') && e.value is String && int.tryParse(e.value! as String) != null
          ? int.parse(e.value! as String)
          : e.value,
  };

  String _kind(PaymentKind kind) => switch (kind) {
    PaymentKind.donation => 'donation',
    PaymentKind.coinPackage => 'coin_package',
    PaymentKind.subscription => 'subscription',
    PaymentKind.order => 'order',
    PaymentKind.adCampaign => 'ad_campaign',
  };

  WalletTransaction _fromPayment(Payment p) => WalletTransaction(
    id: p.id,
    kind: switch (p.kind) {
      PaymentKind.donation => TransactionKind.donation,
      PaymentKind.coinPackage => TransactionKind.purchase,
      PaymentKind.subscription => TransactionKind.subscription,
      PaymentKind.order => TransactionKind.store,
      PaymentKind.adCampaign => TransactionKind.bonus,
    },
    description: p.status == PaymentStatus.refunded ? '${p.description} (reembolsado)' : p.description,
    date: p.paidAt ?? p.createdAt,
    money: -p.amount,
  );

  WalletTransaction _fromLedger(Map<String, dynamic> row) {
    final reason = row['reason'] as String;
    final counterpart = (row['counterpart'] as Map<String, dynamic>?)?['name'] as String?;
    final note = row['note'] as String?;
    final (kind, description) = switch (reason) {
      'coins_sent' => (TransactionKind.coinsSent, 'Para ${counterpart ?? 'alguém'}'),
      'coins_received' => (TransactionKind.coinsReceived, 'De ${counterpart ?? 'alguém'}'),
      'signup_bonus' => (TransactionKind.bonus, 'Boas-vindas ao Save Easy'),
      'invite_reward' => (TransactionKind.bonus, 'Convite'),
      'participation_reward' => (TransactionKind.participation, 'Participação em ação'),
      'donation_reward' => (TransactionKind.donation, 'Recompensa por doação'),
      'coins_donated' => (TransactionKind.donation, 'Doação com moedas'),
      'reward_redeemed' => (TransactionKind.reward, 'Item resgatado'),
      'achievement_claimed' => (TransactionKind.reward, 'Conquista resgatada'),
      'coin_purchase' => (TransactionKind.purchase, 'Pacote de moedas'),
      'store_purchase_reward' => (TransactionKind.store, 'Bônus de compra na loja'),
      'subscription_reward' => (TransactionKind.subscription, 'Bônus de inscrição'),
      'story_created' => (TransactionKind.bonus, 'Story publicado'),
      'ad_viewed' => (TransactionKind.bonus, 'Anúncio assistido'),
      _ => (TransactionKind.bonus, 'Moedas'),
    };
    return WalletTransaction(
      id: 'l${row['id']}',
      kind: kind,
      description: note == null ? description : '$description · "$note"',
      date: DateTime.parse(row['created_at'] as String),
      coins: row['amount'] as int,
    );
  }
}
