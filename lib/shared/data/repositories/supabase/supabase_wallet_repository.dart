import 'package:supabase_flutter/supabase_flutter.dart';

import '../../datasources/mock_database.dart';
import '../../models/models.dart';
import '../wallet_repository.dart';
import 'supabase_guard.dart';

/// Carteira híbrida durante a transição para o back-end:
/// - moedas (enviar e extrato) já são do Supabase (`send_coins`, `coin_ledger`);
/// - dinheiro em R$, pacotes, loja e inscrições continuam no mock até a fase de
///   pagamentos (ver docs/RELATORIO_DESENVOLVIMENTO.md).
class SupabaseWalletRepository extends WalletRepository {
  SupabaseWalletRepository(this._client, MockDatabase db) : super(db);

  final SupabaseClient _client;

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
    final user = AppUser.fromJson(json);
    await db.mirrorUser(user);
    return user;
  });

  /// Extrato de moedas do banco + movimentações em R$ ainda simuladas.
  @override
  Future<List<WalletTransaction>> history() async {
    final money = (await super.history()).where((t) => t.money != 0).toList();
    final coins = await supabaseGuard(() async {
      final rows = await _client
          .from('coin_ledger')
          .select('id, amount, reason, note, created_at, counterpart:profiles!coin_ledger_counterpart_id_fkey(name)')
          .order('created_at', ascending: false)
          .limit(50);
      return rows.map(_fromLedger).toList();
    });
    return [...coins, ...money]..sort((a, b) => b.date.compareTo(a.date));
  }

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
      'reward_redeemed' => (TransactionKind.reward, 'Item resgatado'),
      'achievement_claimed' => (TransactionKind.reward, 'Conquista resgatada'),
      'coin_purchase' => (TransactionKind.purchase, 'Pacote de moedas'),
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
