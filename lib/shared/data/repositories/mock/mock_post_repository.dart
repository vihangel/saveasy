import '../../datasources/mock_database.dart';
import '../../models/models.dart';
import '../app_exception.dart';
import '../post_repository.dart';
import '../user_progress.dart';

class MockPostRepository implements PostRepository {
  MockPostRepository(this._db);

  final MockDatabase _db;

  /// Ids de posts que já deram recompensa de participação (regra: uma vez só).
  final _rewarded = <String>{};

  @override
  Future<List<Post>> feed({
    required FeedTab tab,
    required String userId,
    PostCategory? category,
    String query = '',
  }) async {
    await _db.delay();
    final me = _db.userById(userId);
    final q = query.trim().toLowerCase();
    final posts = _db.posts
        .where((p) {
          if (category != null && !p.categories.contains(category)) return false;
          if (q.isNotEmpty && !'${p.title} ${p.authorName} ${p.type.label}'.toLowerCase().contains(q)) return false;
          return switch (tab) {
            FeedTab.popular => true,
            FeedTab.nearby => p.location != null || p.type == PostType.tutorial,
            FeedTab.following => me.followingIds.contains(p.authorId) || p.authorId == userId,
          };
        })
        .map(_withCounts)
        .toList();
    posts.sort((a, b) => tab == FeedTab.popular ? b.likes.compareTo(a.likes) : b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  @override
  Future<Post> getById(String id) async {
    await _db.delay();
    return _withCounts(_post(id));
  }

  @override
  Future<PostDetailData> detail(String id) async {
    final post = await getById(id);
    final author = _db.users.where((u) => u.id == post.authorId).firstOrNull;
    if (author == null) throw const AppException('Autor não encontrado.');
    return PostDetailData(post: post, author: author, comments: await comments(id));
  }

  @override
  Future<List<Post>> byAuthor(String authorId) async {
    await _db.delay();
    return _db.posts.where((p) => p.authorId == authorId).map(_withCounts).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Post>> saved() async {
    await _db.delay();
    return _db.posts.where((p) => p.saved).map(_withCounts).toList();
  }

  @override
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

  @override
  Future<Post> update(Post post) async {
    await _db.delay();
    await _db.replacePost(post);
    return post;
  }

  @override
  Future<void> delete(String postId) async {
    await _db.delay();
    final post = _post(postId);
    _db.posts = _db.posts.where((p) => p.id != postId).toList();
    await _db.savePosts();
    final author = _db.users.where((u) => u.id == post.authorId).firstOrNull;
    if (author != null) await _db.replaceUser(author.copyWith(postsCount: (author.postsCount - 1).clamp(0, 1 << 30)));
  }

  @override
  Future<Post> toggleLike(String postId) async {
    final post = _post(postId);
    final updated = post.copyWith(liked: !post.liked, likes: post.likes + (post.liked ? -1 : 1));
    await _db.replacePost(updated);
    return _withCounts(updated);
  }

  @override
  Future<Post> toggleSave(String postId) async {
    final post = _post(postId);
    final updated = post.copyWith(saved: !post.saved);
    await _db.replacePost(updated);
    return _withCounts(updated);
  }

  @override
  Future<Post> share(String postId) async {
    final post = _post(postId);
    final updated = post.copyWith(shares: post.shares + 1);
    await _db.replacePost(updated);
    return _withCounts(updated);
  }

  @override
  Future<List<Comment>> comments(String postId) async {
    await _db.delay();
    return _db.comments.where((c) => c.postId == postId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
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

  @override
  Future<Comment> toggleCommentLike(String commentId) async {
    final comment = _db.comments.firstWhere((c) => c.id == commentId);
    final updated = comment.copyWith(liked: !comment.liked, likes: comment.likes + (comment.liked ? -1 : 1));
    _db.comments = [for (final c in _db.comments) c.id == commentId ? updated : c];
    await _db.saveComments();
    return updated;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    _db.comments = _db.comments.where((c) => c.id != commentId).toList();
    await _db.saveComments();
  }

  @override
  Future<(Post, AppUser)> participate({required String postId, required String userId}) async {
    await _db.delay();
    final post = _post(postId);
    final updatedPost = post.copyWith(confirmed: true, attending: post.attending + 1);
    await _db.replacePost(updatedPost);
    var user = _db.userById(userId);
    if (_rewarded.add('$postId:$userId')) {
      user = user.reward(xp: post.rewardXp, coins: post.rewardCoins);
      await _db.replaceUser(user);
    }
    return (_withCounts(updatedPost), user);
  }

  @override
  Future<(Post, AppUser)> cancelParticipation({required String postId, required String userId}) async {
    await _db.delay();
    final post = _post(postId);
    final updatedPost = post.copyWith(confirmed: false, attending: post.attending - 1);
    await _db.replacePost(updatedPost);
    return (_withCounts(updatedPost), _db.userById(userId));
  }

  Post _post(String id) {
    final post = _db.posts.where((p) => p.id == id).firstOrNull;
    if (post == null) throw const AppException('Publicação não encontrada.');
    return post;
  }

  Post _withCounts(Post post) => post.copyWith(commentsCount: _db.comments.where((c) => c.postId == post.id).length);
}
