import '../../datasources/mock_database.dart';
import '../../models/models.dart';
import '../app_exception.dart';
import '../user_repository.dart';

class MockUserRepository implements UserRepository {
  MockUserRepository(this._db);

  final MockDatabase _db;

  @override
  Future<AppUser> getById(String id) async {
    await _db.delay();
    final user = _db.users.where((u) => u.id == id).firstOrNull;
    if (user == null) throw const AppException('Perfil não encontrado.');
    return user;
  }

  @override
  Future<List<AppUser>> search(String query, {String? excludeId}) async {
    await _db.delay();
    final q = query.trim().toLowerCase();
    return _db.users
        .where((u) => u.id != excludeId && u.onboardingCompleted)
        .where((u) => q.isEmpty || u.name.toLowerCase().contains(q) || u.username.contains(q))
        .toList();
  }

  @override
  Future<AppUser> update(AppUser user) async {
    await _db.delay();
    final taken = _db.users.any((u) => u.id != user.id && u.username == user.username);
    if (taken) throw const AppException('Esse nome de usuário já está em uso.');
    await _db.replaceUser(user);
    return user;
  }

  @override
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

  @override
  Future<List<AppUser>> followList(String profileId, FollowListKind kind) async {
    await _db.delay();
    final profile = _db.userById(profileId);
    return switch (kind) {
      FollowListKind.following => _db.users.where((u) => profile.followingIds.contains(u.id)).toList(),
      FollowListKind.followers => _db.users.where((u) => u.followingIds.contains(profileId)).toList(),
    };
  }
}
