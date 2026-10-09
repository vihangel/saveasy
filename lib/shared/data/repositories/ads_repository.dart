import '../models/models.dart';

/// Anúncios: orçamento, campanhas do anunciante e veiculação. Implementações:
/// [MockAdsRepository] e [SupabaseAdsRepository]. O pagamento usa
/// [PaymentIntent.adCampaign] no checkout.
abstract interface class AdsRepository {
  Future<AdQuote> quote(AdFormat format, AdPlan plan, List<String> cities);

  Future<AdCampaign> create({
    required AdFormat format,
    required AdPlan plan,
    required String title,
    String body = '',
    String? imageUrl,
    String ctaLabel = 'Saiba mais',
    String? linkUrl,
    String? postId,
    List<String> cities = const [],
  });

  Future<List<AdCampaign>> myCampaigns();

  Future<AdCampaign> setPaused(String campaignId, {required bool paused});

  Future<void> delete(String campaignId);

  /// Anúncios ativos para a região de quem vê.
  Future<List<AdCampaign>> next(AdFormat format, {int limit = 1});

  Future<void> trackImpression(String campaignId);

  Future<void> trackClick(String campaignId);
}
