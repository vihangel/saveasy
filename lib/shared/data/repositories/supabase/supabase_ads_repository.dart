import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../ads_repository.dart';
import '../app_exception.dart';
import 'supabase_guard.dart';

/// Anúncios via RPC (supabase/migrations/*_ads.sql).
class SupabaseAdsRepository implements AdsRepository {
  SupabaseAdsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AdQuote> quote(AdFormat format, AdPlan plan, List<String> cities) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'ad_quote',
      params: {'p_format': format.json, 'p_plan': plan.name, 'p_cities': cities},
    );
    return AdQuote.fromJson(json);
  });

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
  }) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'create_ad_campaign',
      params: {
        'p': {
          'format': format.json,
          'plan': plan.name,
          'title': title.trim(),
          'body': body.trim(),
          'imageUrl': imageUrl,
          'ctaLabel': ctaLabel.trim(),
          'linkUrl': linkUrl?.trim(),
          'postId': postId,
          'cities': cities,
        },
      },
    );
    return AdCampaign.fromJson(json);
  });

  @override
  Future<List<AdCampaign>> myCampaigns() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('my_ad_campaigns');
    return list.map((c) => AdCampaign.fromJson(c as Map<String, dynamic>)).toList();
  });

  @override
  Future<AdCampaign> setPaused(String campaignId, {required bool paused}) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'set_ad_campaign_paused',
      params: {'p_campaign_id': _id(campaignId), 'p_paused': paused},
    );
    return AdCampaign.fromJson(json);
  });

  @override
  Future<void> delete(String campaignId) =>
      supabaseGuard(() => _client.rpc<void>('delete_ad_campaign', params: {'p_campaign_id': _id(campaignId)}));

  @override
  Future<List<AdCampaign>> next(AdFormat format, {int limit = 1}) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('next_ads', params: {'p_format': format.json, 'p_limit': limit});
    return list.map((c) => AdCampaign.fromJson(c as Map<String, dynamic>)).toList();
  });

  @override
  Future<void> trackImpression(String campaignId) => _track(campaignId, 'impression');

  @override
  Future<void> trackClick(String campaignId) => _track(campaignId, 'click');

  /// Métrica não pode quebrar a tela: erros são ignorados.
  Future<void> _track(String campaignId, String kind) async {
    try {
      await _client.rpc<void>('track_ad', params: {'p_campaign_id': _id(campaignId), 'p_kind': kind});
    } catch (_) {}
  }

  int _id(String id) {
    final parsed = int.tryParse(id);
    if (parsed == null) throw const AppException('Campanha não encontrada.');
    return parsed;
  }
}
