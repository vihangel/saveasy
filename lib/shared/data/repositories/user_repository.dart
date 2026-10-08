import '../models/models.dart';

/// Listas da tela de seguidores.
enum FollowListKind { followers, following }

/// Perfis, busca e seguir. Implementações: [MockUserRepository] e
/// [SupabaseUserRepository].
abstract interface class UserRepository {
  Future<AppUser> getById(String id);

  Future<List<AppUser>> search(String query, {String? excludeId});

  /// Salva nome, @, bio, pronomes, foto e capa do usuário logado.
  Future<AppUser> update(AppUser user);

  /// Segue/deixa de seguir. Retorna o usuário logado atualizado.
  Future<AppUser> toggleFollow({required String meId, required String targetId});

  Future<List<AppUser>> followList(String profileId, FollowListKind kind);
}
