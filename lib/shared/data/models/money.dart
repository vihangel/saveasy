import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_user.dart';
import 'product.dart';

part 'money.freezed.dart';
part 'money.g.dart';

@freezed
abstract class CoinPackage with _$CoinPackage {
  const factory CoinPackage({required String id, required int coins, required double price}) = _CoinPackage;

  factory CoinPackage.fromJson(Map<String, dynamic> json) => _$CoinPackageFromJson(json);
}

enum PaymentKind {
  donation,
  @JsonValue('coin_package')
  coinPackage,
  subscription,
  order,
  @JsonValue('ad_campaign')
  adCampaign,
}

enum PaymentStatus { pending, paid, failed, refunded, expired }

/// O que está sendo pago. O valor é calculado pelo banco a partir disso.
class PaymentIntent {
  const PaymentIntent._(this.kind, this.params);

  factory PaymentIntent.donation({required String postId, required double amount}) =>
      PaymentIntent._(PaymentKind.donation, {'postId': postId, 'amount': amount});

  factory PaymentIntent.coins(CoinPackage package) =>
      PaymentIntent._(PaymentKind.coinPackage, {'packageId': package.id});

  factory PaymentIntent.subscription({required String planId}) =>
      PaymentIntent._(PaymentKind.subscription, {'planId': planId});

  factory PaymentIntent.order({required String productId, int quantity = 1, String shippingAddress = ''}) =>
      PaymentIntent._(PaymentKind.order, {
        'productId': productId,
        'quantity': quantity,
        'shippingAddress': shippingAddress,
      });

  factory PaymentIntent.adCampaign({required String campaignId}) =>
      PaymentIntent._(PaymentKind.adCampaign, {'campaignId': campaignId});

  final PaymentKind kind;
  final Map<String, Object?> params;
}

@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required String id,
    required PaymentKind kind,
    required double amount,
    required PaymentStatus status,
    required DateTime createdAt,
    @Default('') String description,
    String? pixCode,
    DateTime? expiresAt,
    DateTime? paidAt,

    /// Ambiente de testes: o app pode simular a confirmação do Pix.
    @Default(false) bool sandbox,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}

@freezed
abstract class DonationFund with _$DonationFund {
  const factory DonationFund({
    @Default(0) double balance,
    @Default(0) double received,
    @Default(0) double paidOut,
    @Default(100) int coinsPerReal,
  }) = _DonationFund;

  factory DonationFund.fromJson(Map<String, dynamic> json) => _$DonationFundFromJson(json);
}

@freezed
abstract class SubscriptionPlan with _$SubscriptionPlan {
  const factory SubscriptionPlan({
    required String id,
    required String name,
    required double price,
    @Default(1) int months,
    @Default('') String benefits,
  }) = _SubscriptionPlan;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => _$SubscriptionPlanFromJson(json);
}

@freezed
abstract class MySubscription with _$MySubscription {
  const MySubscription._();

  const factory MySubscription({required String status, required DateTime currentPeriodEnd, String? planId}) =
      _MySubscription;

  factory MySubscription.fromJson(Map<String, dynamic> json) => _$MySubscriptionFromJson(json);

  bool get isActive => currentPeriodEnd.isAfter(DateTime.now()) && status != 'expired';
}

@freezed
abstract class CommunityPlans with _$CommunityPlans {
  const factory CommunityPlans({
    @Default(<SubscriptionPlan>[]) List<SubscriptionPlan> plans,
    @Default(0) int subscribers,
    MySubscription? mine,
  }) = _CommunityPlans;

  factory CommunityPlans.fromJson(Map<String, dynamic> json) => _$CommunityPlansFromJson(json);
}

@freezed
abstract class Payout with _$Payout {
  const factory Payout({
    required String id,
    required double amount,
    required String status,
    required DateTime createdAt,
  }) = _Payout;

  factory Payout.fromJson(Map<String, dynamic> json) => _$PayoutFromJson(json);
}

/// Painel financeiro de comunidades, empresas e influenciadores.
@freezed
abstract class FinanceSummary with _$FinanceSummary {
  const factory FinanceSummary({
    @Default(0) double donations,
    @Default(0) double donationsFromCoins,
    @Default(0) int donationsCount,
    @Default(0) double subscriptions,
    @Default(0) int activeSubscribers,
    @Default(0) double sales,
    @Default(0) int salesCount,
    @Default(0) int ordersToShip,
    @Default(0) double feePercent,
    @Default(0) double payouts,
    @Default(0) double available,
    @Default(<Payout>[]) List<Payout> payoutHistory,
  }) = _FinanceSummary;

  factory FinanceSummary.fromJson(Map<String, dynamic> json) => _$FinanceSummaryFromJson(json);
}

enum OrderStatus {
  @JsonValue('pending_payment')
  pendingPayment('Aguardando pagamento'),
  paid('Pago'),
  shipped('Enviado'),
  delivered('Entregue'),
  cancelled('Cancelado');

  const OrderStatus(this.label);

  final String label;
}

@freezed
abstract class StoreOrder with _$StoreOrder {
  const factory StoreOrder({
    required String id,
    required String productName,
    required int quantity,
    required double unitPrice,
    required double total,
    required OrderStatus status,
    required DateTime createdAt,
    String? productId,
    @Default('') String shippingAddress,
    AppUser? buyer,
    AppUser? seller,
    @Default(false) bool reviewed,
  }) = _StoreOrder;

  factory StoreOrder.fromJson(Map<String, dynamic> json) => _$StoreOrderFromJson(json);
}

@freezed
abstract class ProductReview with _$ProductReview {
  const factory ProductReview({
    required int rating,
    required DateTime createdAt,
    @Default('') String comment,
    @Default('') String authorName,
    String? authorAvatarUrl,
  }) = _ProductReview;

  factory ProductReview.fromJson(Map<String, dynamic> json) => _$ProductReviewFromJson(json);
}

@freezed
abstract class ProductDetail with _$ProductDetail {
  const factory ProductDetail({required Product product, @Default(<ProductReview>[]) List<ProductReview> reviews}) =
      _ProductDetail;

  factory ProductDetail.fromJson(Map<String, dynamic> json) => _$ProductDetailFromJson(json);
}
