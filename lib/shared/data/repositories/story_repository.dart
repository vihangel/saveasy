import '../datasources/mock_database.dart';
import '../models/models.dart';
import 'user_progress.dart';

class StoryRepository {
  StoryRepository(this._db);

  final MockDatabase _db;

  Future<List<Story>> stories() async {
    await _db.delay();
    return [..._db.stories]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markSeen(String id) async {
    _db.stories = [for (final s in _db.stories) s.id == id ? s.copyWith(seen: true) : s];
    await _db.saveStories();
  }

  /// Recompensa por assistir um story de propaganda (uma vez por story).
  Future<AppUser?> rewardAdView({required String storyId, required String userId}) async {
    final story = _db.stories.firstWhere((s) => s.id == storyId);
    if (story.type != PostType.ad || story.seen) return null;
    final updated = _db.userById(userId).reward(coins: 20);
    await _db.replaceUser(updated);
    return updated;
  }

  /// Publica um story e retorna o autor com as moedas ganhas.
  Future<AppUser> create({
    required AppUser author,
    required PostType type,
    required String text,
    String? imageUrl,
  }) async {
    await _db.delay();
    final story = Story(
      id: _db.newId('s'),
      authorId: author.id,
      authorName: author.name,
      authorAvatarUrl: author.avatarUrl,
      imageUrl: imageUrl,
      type: type,
      text: text.trim(),
      createdAt: DateTime.now(),
      seen: true,
    );
    _db.stories = [story, ..._db.stories];
    await _db.saveStories();
    final updated = _db.userById(author.id).reward(xp: 20, coins: 20);
    await _db.replaceUser(updated);
    return updated;
  }
}
