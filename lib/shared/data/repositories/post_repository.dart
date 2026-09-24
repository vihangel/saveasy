import '../datasources/mock_database.dart';
import '../models/models.dart';
import 'user_progress.dart';

/// Seções do feed (as abas do topo no Figma).
enum FeedTab { popular, nearby, following }

class PostRepository {
  PostRepository(this._db);

  final MockDatabase _db;

  Future<List<Post>> feed({
    required FeedTab tab,
    required String userId,
    PostCategory? category,
    String query = '',
  }) async {
    await _db.delay();
    final me = _db.userById(userId);
    final q = query.trim().toLowerCase();
    var posts = _db.posts.where((p) {
      if (category != null && !p.categories.contains(category)) return false;
      if (q.isNotEmpty && !'${p.title} ${p.authorName} ${p.type.label}'.toLowerCase().contains(q)) {
        return false;
      }
      return switch (tab) {
        FeedTab.popular => true,
        FeedTab.nearby => p.location != null || p.type == PostType.tutorial,
        FeedTab.following => me.followingIds.contains(p.authorId) || p.authorId == userId,
      };
    }).toList();
    posts.sort((a, b) => tab == FeedTab.popular ? b.likes.compareTo(a.likes) : b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<Post> getById(String id) async {
    await _db.delay();
    return _db.posts.firstWhere((p) => p.id == id);
  }

  Future<List<Post>> byAuthor(String authorId) async {
    await _db.delay();
    return _db.posts.where((p) => p.authorId == authorId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Publica e retorna o post criado junto com o autor atualizado (+XP).
  Future<(Post, AppUser)> create(Post draft) async {
    await _db.delay();
    final post = draft.copyWith(id: _db.newId('p'), createdAt: DateTime.now());
    _db.posts = [post, ..._db.posts];
    await _db.savePosts();
    final author = _db.userById(post.authorId);
    final updated = author.copyWith(postsCount: author.postsCount + 1).reward(xp: 30);
    await _db.replaceUser(updated);
    return (post, updated);
  }

  Future<Post> toggleLike(String postId) async {
    final post = _db.posts.firstWhere((p) => p.id == postId);
    final updated = post.copyWith(liked: !post.liked, likes: post.likes + (post.liked ? -1 : 1));
    await _db.replacePost(updated);
    return updated;
  }

  Future<Post> toggleSave(String postId) async {
    final post = _db.posts.firstWhere((p) => p.id == postId);
    final updated = post.copyWith(saved: !post.saved);
    await _db.replacePost(updated);
    return updated;
  }

  Future<Post> share(String postId) async {
    final post = _db.posts.firstWhere((p) => p.id == postId);
    final updated = post.copyWith(shares: post.shares + 1);
    await _db.replacePost(updated);
    return updated;
  }

  int commentCount(String postId) => _db.comments.where((c) => c.postId == postId).length;

  Future<List<Comment>> comments(String postId) async {
    await _db.delay();
    return _db.comments.where((c) => c.postId == postId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Comment> addComment({required String postId, required String authorName, required String text}) async {
    await _db.delay();
    final comment = Comment(
      id: _db.newId('c'),
      postId: postId,
      authorName: authorName,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    _db.comments = [..._db.comments, comment];
    await _db.saveComments();
    return comment;
  }

  Future<Comment> toggleCommentLike(String commentId) async {
    final comment = _db.comments.firstWhere((c) => c.id == commentId);
    final updated = comment.copyWith(liked: !comment.liked, likes: comment.likes + (comment.liked ? -1 : 1));
    _db.comments = [for (final c in _db.comments) c.id == commentId ? updated : c];
    await _db.saveComments();
    return updated;
  }

  /// Confirma presença em evento / participação em ação social ou atividade.
  /// Retorna o post atualizado e o usuário com as recompensas aplicadas.
  Future<(Post, AppUser)> participate({required String postId, required String userId}) async {
    await _db.delay();
    final post = _db.posts.firstWhere((p) => p.id == postId);
    final updatedPost = post.copyWith(confirmed: true, attending: post.attending + 1);
    await _db.replacePost(updatedPost);
    final user = _db.userById(userId).reward(xp: post.rewardXp, coins: post.rewardCoins);
    await _db.replaceUser(user);
    return (updatedPost, user);
  }

  Future<(Post, AppUser)> cancelParticipation({required String postId, required String userId}) async {
    await _db.delay();
    final post = _db.posts.firstWhere((p) => p.id == postId);
    final updatedPost = post.copyWith(confirmed: false, attending: post.attending - 1);
    await _db.replacePost(updatedPost);
    return (updatedPost, _db.userById(userId));
  }
}
