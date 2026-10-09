import '../../models/models.dart';
import '../ads_repository.dart';
import '../app_exception.dart';

/// Anúncios locais: sem veiculação real (a barra mostra o convite para anunciar).
class MockAdsRepository implements AdsRepository {
  final _campaigns = <AdCampaign>[];

  static const _daily = {AdFormat.bar: 9.90, AdFormat.boostedPost: 14.90, AdFormat.story: 7.90};
  static const _days = {AdPlan.daily: 1, AdPlan.weekly: 7, AdPlan.monthly: 30};
  static const _discount = {AdPlan.daily: 0.0, AdPlan.weekly: 0.15, AdPlan.monthly: 0.30};

  @override
  Future<AdQuote> quote(AdFormat format, AdPlan plan, List<String> cities) async {
    final days = _days[plan]!;
    final extra = 1 + 0.3 * (cities.length > 1 ? cities.length - 1 : 0);
    final price = (_daily[format]! * days * (1 - _discount[plan]!) * extra * 100).round() / 100;
    return AdQuote(days: days, price: price, dailyPrice: _daily[format]!, discount: _discount[plan]!);
  }

  @override
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
  }) async {
    if (title.trim().length < 3) throw const AppException('Confira o título (3 a 60 letras).');
    final campaign = AdCampaign(
      id: 'ad${_campaigns.length + 1}',
      format: format,
      plan: plan,
      title: title.trim(),
      body: body,
      status: AdStatus.pendingPayment,
      price: (await quote(format, plan, cities)).price,
      createdAt: DateTime.now(),
      ctaLabel: ctaLabel,
      linkUrl: linkUrl,
      postId: postId,
      cities: cities,
    );
    _campaigns.insert(0, campaign);
    return campaign;
  }

  @override
  Future<List<AdCampaign>> myCampaigns() async => _campaigns;

  @override
  Future<AdCampaign> setPaused(String campaignId, {required bool paused}) async {
    final i = _campaigns.indexWhere((c) => c.id == campaignId);
    if (i < 0) throw const AppException('Campanha não encontrada.');
    return _campaigns[i] = _campaigns[i].copyWith(status: paused ? AdStatus.paused : AdStatus.active);
  }

  @override
  Future<void> delete(String campaignId) async => _campaigns.removeWhere((c) => c.id == campaignId);

  @override
  Future<List<AdCampaign>> next(AdFormat format, {int limit = 1}) async => const [];

  @override
  Future<void> trackImpression(String campaignId) async {}

  @override
  Future<void> trackClick(String campaignId) async {}
}
