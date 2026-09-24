import '../datasources/mock_database.dart';
import '../models/models.dart';

class UserRepository {
  UserRepository(this._db);

  final MockDatabase _db;

  Future<AppUser> getById(String id) async {
    await _db.delay();
    return _db.userById(id);
  }

  AppUser currentSnapshot(String id) => _db.userById(id);

  Future<List<AppUser>> search(String query, {String? excludeId}) async {
    await _db.delay();
    final q = query.trim().toLowerCase();
    return _db.users
        .where((u) => u.id != excludeId)
        .where((u) => q.isEmpty || u.name.toLowerCase().contains(q) || u.username.contains(q))
        .toList();
  }

  Future<AppUser> update(AppUser user) async {
    await _db.delay();
    await _db.replaceUser(user);
    return user;
  }

  /// Segue/deixa de seguir. Retorna o usuário logado atualizado.
  Future<AppUser> toggleFollow({required String meId, required String targetId}) async {
    await _db.delay();
    final me = _db.userById(meId);
    final target = _db.userById(targetId);
    final following = me.followingIds.contains(targetId);
    final updatedMe = me.copyWith(
      followingIds: following ? me.followingIds.where((id) => id != targetId).toList() : [...me.followingIds, targetId],
      following: me.following + (following ? -1 : 1),
    );
    await _db.replaceUser(updatedMe);
    await _db.replaceUser(target.copyWith(followers: target.followers + (following ? -1 : 1)));
    return updatedMe;
  }
}
