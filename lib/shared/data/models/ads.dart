import 'package:freezed_annotation/freezed_annotation.dart';

import 'post.dart';

part 'ads.freezed.dart';
part 'ads.g.dart';

enum AdFormat {
  bar('Barra de anúncio', 'Aparece fixa acima do menu, para todos da sua região.'),
  @JsonValue('boosted_post')
  boostedPost('Post impulsionado', 'Uma publicação sua em destaque no feed, marcada como patrocinada.'),
  story('Story patrocinado', 'Aparece nos stories; quem assiste ganha moedas.');

  const AdFormat(this.label, this.description);

  final String label;
  final String description;

  String get json => switch (this) {
    bar => 'bar',
    boostedPost => 'boosted_post',
    story => 'story',
  };
}

enum AdStatus {
  @JsonValue('pending_payment')
  pendingPayment('Aguardando pagamento'),
  @JsonValue('in_review')
  inReview('Em análise'),
  active('Ativa'),
  paused('Pausada'),
  rejected('Recusada'),
  ended('Encerrada');

  const AdStatus(this.label);

  final String label;
}

enum AdPlan {
  daily('Diário'),
  weekly('Semanal'),
  monthly('Mensal');

  const AdPlan(this.label);

  final String label;
}

@freezed
abstract class AdCampaign with _$AdCampaign {
  const AdCampaign._();

  const factory AdCampaign({
    required String id,
    required AdFormat format,
    required AdPlan plan,
    required String title,
    required AdStatus status,
    required double price,
    required DateTime createdAt,
    @Default('') String body,
    @Default('Saiba mais') String ctaLabel,
    String? imageUrl,
    String? linkUrl,
    String? postId,
    @Default(<String>[]) List<String> cities,
    String? reviewNote,
    @Default(0) int impressions,
    @Default(0) int clicks,
    DateTime? startsAt,
    DateTime? endsAt,
    String? ownerId,
    @Default('') String ownerName,
    String? ownerAvatarUrl,

    /// Publicação impulsionada (só no formato boosted_post).
    Post? post,
  }) = _AdCampaign;

  factory AdCampaign.fromJson(Map<String, dynamic> json) => _$AdCampaignFromJson(json);

  double get ctr => impressions == 0 ? 0 : clicks / impressions;
}

@freezed
abstract class AdQuote with _$AdQuote {
  const factory AdQuote({
    required int days,
    required double price,
    @Default(0) double dailyPrice,
    @Default(0) double discount,
    @Default(0.3) double fundShare,
  }) = _AdQuote;

  factory AdQuote.fromJson(Map<String, dynamic> json) => _$AdQuoteFromJson(json);
}
