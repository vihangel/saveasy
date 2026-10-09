import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../app_exception.dart';
import '../gamification_repository.dart';
import 'supabase_guard.dart';

/// Recompensas, conquistas, convites e currículo
/// (supabase/migrations/*_gamification.sql).
class SupabaseGamificationRepository implements GamificationRepository {
  SupabaseGamificationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Reward>> rewards({RewardKind? kind}) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>(
      'rewards_catalog',
      params: {'p_kind': kind == null ? null : _kind(kind)},
    );
    return list.map((r) => Reward.fromJson(r as Map<String, dynamic>)).toList();
  });

  @override
  Future<Reward> rewardById(String id) async {
    final match = (await rewards()).where((r) => r.id == id).firstOrNull;
    if (match == null) throw const AppException('Recompensa não encontrada.');
    return match;
  }

  @override
  Future<List<Reward>> rewardsByIds(Iterable<String> ids) => supabaseGuard(() async {
    if (ids.isEmpty) return <Reward>[];
    final list = await _client.rpc<List<dynamic>>('rewards_by_ids', params: {'p_ids': ids.toList()});
    return list.map((r) => Reward.fromJson(r as Map<String, dynamic>)).toList();
  });

  @override
  Future<(Reward, AppUser)> redeem({required String rewardId, required String userId}) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('redeem_reward', params: {'p_reward_id': rewardId});
    return (
      Reward.fromJson(json['reward'] as Map<String, dynamic>),
      AppUser.fromJson(json['me'] as Map<String, dynamic>),
    );
  });

  @override
  Future<AppUser> equip({required String userId, String? titleId, List<String> badgeIds = const [], String? coverId}) =>
      supabaseGuard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'equip_rewards',
          params: {'p_title_id': titleId, 'p_badge_ids': badgeIds, 'p_cover_id': coverId},
        );
        return AppUser.fromJson(json);
      });

  @override
  Future<List<Achievement>> achievements() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('my_achievements');
    return list.map((a) => Achievement.fromJson(a as Map<String, dynamic>)).toList();
  });

  @override
  Future<(Achievement, AppUser)> claim({required String achievementId, required String userId}) =>
      supabaseGuard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'claim_achievement',
          params: {'p_achievement_id': achievementId},
        );
        final updated = (await achievements()).firstWhere((a) => a.id == achievementId);
        return (updated, AppUser.fromJson(json));
      });

  @override
  Future<InviteInfo> invite() => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('my_invite');
    return InviteInfo.fromJson(json);
  });

  @override
  Future<AppUser> redeemInvite(String code, {required String userId}) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('redeem_invite', params: {'p_code': code.trim()});
    return AppUser.fromJson(json);
  });

  @override
  Future<ActionResume> actionResume(String profileId, {DateTime? from, DateTime? to}) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'action_resume',
      params: {
        'p_profile_id': profileId,
        'p_from': from?.toUtc().toIso8601String(),
        'p_to': to?.toUtc().toIso8601String(),
      },
    );
    return ActionResume.fromJson(json);
  });

  String _kind(RewardKind kind) => switch (kind) {
    RewardKind.cover => 'cover',
    RewardKind.badge => 'badge',
    RewardKind.title => 'title',
  };
}
