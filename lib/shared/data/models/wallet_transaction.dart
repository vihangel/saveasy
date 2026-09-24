import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_transaction.freezed.dart';
part 'wallet_transaction.g.dart';

enum TransactionKind {
  @JsonValue('purchase')
  purchase('Compra de moedas'),
  @JsonValue('donation')
  donation('Doação'),
  @JsonValue('subscription')
  subscription('Inscrição'),
  @JsonValue('coins_sent')
  coinsSent('Moedas enviadas'),
  @JsonValue('reward')
  reward('Recompensa'),
  @JsonValue('store')
  store('Loja');

  const TransactionKind(this.label);

  final String label;
}

@freezed
abstract class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required TransactionKind kind,
    required String description,
    required DateTime date,
    @Default(0) int coins,
    @Default(0) double money,
  }) = _WalletTransaction;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => _$WalletTransactionFromJson(json);
}

class CoinPackage {
  const CoinPackage({required this.coins, required this.price});

  final int coins;
  final double price;
}
