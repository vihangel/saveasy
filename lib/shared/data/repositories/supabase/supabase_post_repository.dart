import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../app_exception.dart';
import '../post_repository.dart';
import 'supabase_guard.dart';

/// Publicações via RPCs orientadas às telas (supabase/migrations/*_screen_rpcs.sql).
/// As funções já devolvem JSON no formato do [Post] / [Comment] / [AppUser].
class SupabasePostRepository implements PostRepository {
  SupabasePostRepository(this._client);

  final SupabaseClient _client;

  static const _adPlans = {'Diário': 'daily', 'Semanal': 'weekly', 'Mensal': 'monthly'};

  @override
  Future<List<Post>> feed({required FeedTab tab, required String userId, PostCategory? category, String query = ''}) =>
      supabaseGuard(() async {
        final list = await _client.rpc<List<dynamic>>(
          'feed',
          params: {
            'p_tab': tab.name,
            // Os valores JSON das categorias são iguais aos nomes do enum.
            'p_category': category?.name,
            'p_query': query.trim(),
          },
        );
        return list.map(_post).toList();
      });

  @override
  Future<Post> getById(String id) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>?>('post_json_by_id', params: {'p_post_id': _id(id)});
    if (json == null) throw const AppException('Publicação não encontrada.');
    return _post(json);
  });

  @override
  Future<PostDetailData> detail(String id) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>?>('post_detail', params: {'p_post_id': _id(id)});
    if (json == null) throw const AppException('Publicação não encontrada.');
    return PostDetailData(
      post: _post(json['post']),
      author: AppUser.fromJson(json['author'] as Map<String, dynamic>),
      comments: (json['comments'] as List).map((c) => Comment.fromJson(c as Map<String, dynamic>)).toList(),
    );
  });

  @override
  Future<List<Post>> byAuthor(String authorId) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('author_posts', params: {'p_profile_id': authorId});
    return list.map(_post).toList();
  });

  @override
  Future<List<Post>> saved() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('my_interests');
    return list.map(_post).toList();
  });

  @override
  Future<(Post, AppUser)> create(Post draft) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('create_post', params: {'p': _payload(draft)});
    return (_post(json['post']), AppUser.fromJson(json['author'] as Map<String, dynamic>));
  });

  @override
  Future<Post> update(Post post) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'update_post',
      params: {'p_post_id': _id(post.id), 'p': _payload(post)},
    );
    return _post(json);
  });

  @override
  Future<void> delete(String postId) =>
      supabaseGuard(() => _client.rpc<void>('delete_post', params: {'p_post_id': _id(postId)}));

  @override
  Future<Post> toggleLike(String postId) => _postRpc('toggle_post_like', postId);

  @override
  Future<Post> toggleSave(String postId) => _postRpc('toggle_post_interest', postId);

  @override
  Future<Post> share(String postId) => _postRpc('share_post', postId);

  @override
  Future<List<Comment>> comments(String postId) async => (await detail(postId)).comments;

  @override
  Future<Comment> addComment({required String postId, required String authorName, required String text}) =>
      supabaseGuard(() async {
        final json = await _client.rpc<Map<String, dynamic>>(
          'add_comment',
          params: {'p_post_id': _id(postId), 'p_body': text.trim()},
        );
        return Comment.fromJson(json);
      });

  @override
  Future<Comment> toggleCommentLike(String commentId) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'toggle_comment_like',
      params: {'p_comment_id': _id(commentId)},
    );
    return Comment.fromJson(json);
  });

  @override
  Future<void> deleteComment(String commentId) =>
      supabaseGuard(() => _client.rpc<void>('delete_comment', params: {'p_comment_id': _id(commentId)}));

  @override
  Future<(Post, AppUser)> participate({required String postId, required String userId}) =>
      _participation('participate', postId);

  @override
  Future<(Post, AppUser)> cancelParticipation({required String postId, required String userId}) =>
      _participation('cancel_participation', postId);

  Future<(Post, AppUser)> _participation(String fn, String postId) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(fn, params: {'p_post_id': _id(postId)});
    return (_post(json['post']), AppUser.fromJson(json['me'] as Map<String, dynamic>));
  });

  Future<Post> _postRpc(String fn, String postId) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(fn, params: {'p_post_id': _id(postId)});
    return _post(json);
  });

  /// Campos que o autor pode definir (o resto o banco calcula).
  Map<String, dynamic> _payload(Post post) {
    final json = post.toJson();
    const keys = {
      'type',
      'subtype',
      'title',
      'description',
      'imageUrl',
      'categories',
      'tags',
      'targetAmount',
      'recurring',
      'startsAt',
      'endsAt',
      'location',
      'city',
      'state',
      'link',
      'capacity',
      'durationMinutes',
      'steps',
      'activityKind',
    };
    return {
      for (final key in keys)
        if (json.containsKey(key)) key: json[key],
      if (post.adPlan != null) 'adPlan': _adPlans[post.adPlan] ?? post.adPlan,
    };
  }

  /// Converte o JSON do banco no [Post] do app (plano de propaganda em português).
  Post _post(dynamic json) {
    final post = Post.fromJson(json as Map<String, dynamic>);
    final plan = post.adPlan;
    if (plan == null) return post;
    final label = _adPlans.entries.where((e) => e.value == plan).firstOrNull?.key;
    return post.copyWith(adPlan: label ?? plan);
  }

  /// Ids do banco são bigint; conteúdo ainda mockado usa ids textuais.
  int _id(String id) {
    final parsed = int.tryParse(id);
    if (parsed == null) throw const AppException('Publicação não encontrada.');
    return parsed;
  }
}
