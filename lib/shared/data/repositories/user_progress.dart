import '../models/models.dart';

extension UserProgress on AppUser {
  /// Aplica XP e moedas ganhos numa ação e recalcula o nível.
  AppUser reward({int xp = 0, int coins = 0}) {
    final totalXp = this.xp + xp;
    return copyWith(xp: totalXp, coins: this.coins + coins, level: totalXp ~/ AppUser.xpPerLevel + 1);
  }
}
