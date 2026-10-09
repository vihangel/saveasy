import '../models/models.dart';

/// Recompensas, conquistas, convites e currículo de ações. Implementações:
/// [MockGamificationRepository] e [SupabaseGamificationRepository].
abstract interface class GamificationRepository {
  /// Catálogo com `owned`/`equipped` do usuário logado.
  Future<List<Reward>> rewards({RewardKind? kind});

  Future<Reward> rewardById(String id);

  /// Itens exibidos no perfil de alguém (selos e título).
  Future<List<Reward>> rewardsByIds(Iterable<String> ids);

  Future<(Reward, AppUser)> redeem({required String rewardId, required String userId});

  /// Equipa até 1 título, 3 selos e 1 capa. Retorna o usuário atualizado.
  Future<AppUser> equip({required String userId, String? titleId, List<String> badgeIds = const [], String? coverId});

  Future<List<Achievement>> achievements();

  Future<(Achievement, AppUser)> claim({required String achievementId, required String userId});

  Future<InviteInfo> invite();

  /// Usa o código de quem convidou (até 30 dias depois do cadastro).
  Future<AppUser> redeemInvite(String code, {required String userId});

  Future<ActionResume> actionResume(String profileId, {DateTime? from, DateTime? to});
}
