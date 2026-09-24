import '../datasources/mock_database.dart';
import '../models/models.dart';
import 'app_exception.dart';

/// Recompensas (capas, selos e títulos) e conquistas.
class GamificationRepository {
  GamificationRepository(this._db);

  final MockDatabase _db;

  Future<List<Reward>> rewards({RewardKind? kind}) async {
    await _db.delay();
    return _db.rewards.where((r) => kind == null || r.kind == kind).toList();
  }

  Future<Reward> rewardById(String id) async {
    await _db.delay();
    return _db.rewards.firstWhere((r) => r.id == id);
  }

  List<Reward> rewardsByIds(Iterable<String> ids) => _db.rewards.where((r) => ids.contains(r.id)).toList();

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

  Future<List<Achievement>> achievements() async {
    await _db.delay();
    return _db.achievements;
  }

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
}
