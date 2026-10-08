import '../models/models.dart';

/// Seções do feed (as abas do topo).
enum FeedTab { popular, nearby, following }

/// Tudo o que a tela de detalhe mostra, numa chamada só.
class PostDetailData {
  const PostDetailData({required this.post, required this.author, required this.comments});

  final Post post;
  final AppUser author;
  final List<Comment> comments;
}

/// Publicações e interações. Implementações: [MockPostRepository] e
/// [SupabasePostRepository].
abstract interface class PostRepository {
  Future<List<Post>> feed({required FeedTab tab, required String userId, PostCategory? category, String query = ''});

  Future<Post> getById(String id);

  Future<PostDetailData> detail(String id);

  Future<List<Post>> byAuthor(String authorId);

  /// Publicações salvas / "Tenho interesse".
  Future<List<Post>> saved();

  /// Publica e retorna o post criado junto com o autor atualizado (+XP).
  Future<(Post, AppUser)> create(Post draft);

  Future<Post> update(Post post);

  Future<void> delete(String postId);

  Future<Post> toggleLike(String postId);

  Future<Post> toggleSave(String postId);

  Future<Post> share(String postId);

  Future<List<Comment>> comments(String postId);

  Future<Comment> addComment({required String postId, required String authorName, required String text});

  Future<Comment> toggleCommentLike(String commentId);

  Future<void> deleteComment(String commentId);

  /// Confirma presença (evento) ou participação (ação social / atividade).
  /// A recompensa sai uma vez por pessoa e publicação.
  Future<(Post, AppUser)> participate({required String postId, required String userId});

  Future<(Post, AppUser)> cancelParticipation({required String postId, required String userId});
}
