import '../../datasources/mock_database.dart';
import '../../models/models.dart';
import '../story_repository.dart';
import '../user_progress.dart';

class MockStoryRepository implements StoryRepository {
  MockStoryRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<Story>> stories() async {
    await _db.delay();
    return [..._db.stories]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Propaganda dá 20 moedas na primeira visualização.
  @override
  Future<AppUser?> view(String storyId, {required String userId}) async {
    final story = _db.stories.firstWhere((s) => s.id == storyId);
    if (story.seen) return null;
    _db.stories = [for (final s in _db.stories) s.id == storyId ? s.copyWith(seen: true) : s];
    await _db.saveStories();
    if (story.type != PostType.ad || story.authorId == userId) return null;
    final updated = _db.userById(userId).reward(coins: 20);
    await _db.replaceUser(updated);
    return updated;
  }

  @override
  Future<void> delete(String storyId) async {
    _db.stories = _db.stories.where((s) => s.id != storyId).toList();
    await _db.saveStories();
  }

  @override
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
