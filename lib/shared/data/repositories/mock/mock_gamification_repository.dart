import '../../datasources/mock_database.dart';
import '../../models/models.dart';
import '../app_exception.dart';
import '../gamification_repository.dart';
import '../user_progress.dart';

/// Recompensas (capas, selos e títulos), conquistas e convites locais.
class MockGamificationRepository implements GamificationRepository {
  MockGamificationRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<Reward>> rewards({RewardKind? kind}) async {
    await _db.delay();
    return _db.rewards.where((r) => kind == null || r.kind == kind).toList();
  }

  @override
  Future<Reward> rewardById(String id) async {
    await _db.delay();
    return _db.rewards.firstWhere((r) => r.id == id);
  }

  @override
  Future<List<Reward>> rewardsByIds(Iterable<String> ids) async =>
      _db.rewards.where((r) => ids.contains(r.id)).toList();

  @override
  Future<(Reward, AppUser)> redeem({required String rewardId, required String userId}) async {
    await _db.delay();
    final reward = _db.rewards.firstWhere((r) => r.id == rewardId);
    final user = _db.userById(userId);
    if (reward.owned) throw const AppException('Você já possui esse item.');
    if (user.coins < reward.price) throw const AppException('Moedas insuficientes.');
    final updatedReward = reward.copyWith(owned: true);
    _db.rewards = [for (final r in _db.rewards) r.id == rewardId ? updatedReward : r];
    await _db.saveRewards();
    final updatedUser = user.copyWith(coins: user.coins - reward.price);
    await _db.replaceUser(updatedUser);
    return (updatedReward, updatedUser);
  }

  @override
  Future<List<Achievement>> achievements() async {
    await _db.delay();
    return _db.achievements;
  }

  @override
  Future<(Achievement, AppUser)> claim({required String achievementId, required String userId}) async {
    await _db.delay();
    final achievement = _db.achievements.firstWhere((a) => a.id == achievementId);
    if (!achievement.completed || achievement.claimed) {
      throw const AppException('Essa conquista ainda não pode ser resgatada.');
    }
    final updated = achievement.copyWith(claimed: true);
    _db.achievements = [for (final a in _db.achievements) a.id == achievementId ? updated : a];
    await _db.saveAchievements();
    final user = _db.userById(userId);
    final updatedUser = user.copyWith(coins: user.coins + achievement.rewardCoins);
    await _db.replaceUser(updatedUser);
    return (updated, updatedUser);
  }

  @override
  Future<AppUser> equip({
    required String userId,
    String? titleId,
    List<String> badgeIds = const [],
    String? coverId,
  }) async {
    if (badgeIds.length > 3) throw const AppException('Você pode exibir até 3 selos.');
    final updated = _db.userById(userId).copyWith(titleId: titleId, badgeIds: badgeIds, coverRewardId: coverId);
    await _db.replaceUser(updated);
    return updated;
  }

  @override
  Future<InviteInfo> invite() async => const InviteInfo(code: 'demo1234', invited: 2, canRedeem: true);

  @override
  Future<AppUser> redeemInvite(String code, {required String userId}) async {
    await _db.delay();
    if (code.trim().length < 4) throw const AppException('Código de convite inválido.');
    final user = _db.userById(userId);
    final updated = user.reward(coins: 100);
    await _db.replaceUser(updated);
    return updated;
  }

  /// Currículo a partir das publicações do autor no banco local.
  @override
  Future<ActionResume> actionResume(String profileId, {DateTime? from, DateTime? to}) async {
    await _db.delay();
    final items = [
      for (final p in _db.posts.where((p) => p.authorId == profileId))
        if ((from == null || !p.createdAt.isBefore(from)) && (to == null || p.createdAt.isBefore(to)))
          ResumeItem(date: p.createdAt, kind: ResumeKind.post, title: p.title, type: p.type, postId: p.id, xp: 30),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return ActionResume(items: items, totals: {'posts': items.length, 'participations': 0, 'donations': 0});
  }
}
