import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../app_exception.dart';
import '../user_repository.dart';
import 'supabase_guard.dart';

class SupabaseUserRepository implements UserRepository {
  SupabaseUserRepository(this._client);

  final SupabaseClient _client;

  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

  @override
  Future<AppUser> getById(String id) => supabaseGuard(() async {
    // Conteúdo ainda mockado (stories, chat) usa ids que não existem no banco.
    if (!_uuid.hasMatch(id)) throw const AppException('Perfil não encontrado.');
    final json = await _client.rpc<Map<String, dynamic>?>('profile_page', params: {'p_profile_id': id});
    if (json == null) throw const AppException('Perfil não encontrado.');
    return AppUser.fromJson(json);
  });

  @override
  Future<List<AppUser>> search(String query, {String? excludeId}) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('search_profiles', params: {'p_query': query.trim()});
    return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).where((u) => u.id != excludeId).toList();
  });

  @override
  Future<AppUser> update(AppUser user) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'update_my_profile',
      params: {
        'p_name': user.name,
        'p_username': user.username,
        'p_bio': user.bio,
        'p_pronouns': user.pronouns,
        'p_avatar_url': user.avatarUrl,
        'p_cover_url': user.coverUrl,
      },
    );
    return AppUser.fromJson(json);
  });

  @override
  Future<AppUser> toggleFollow({required String meId, required String targetId}) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('toggle_follow', params: {'p_target': targetId});
    return AppUser.fromJson(json);
  });

  @override
  Future<List<AppUser>> followList(String profileId, FollowListKind kind) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>(
      'follow_list',
      params: {'p_profile_id': profileId, 'p_kind': kind.name},
    );
    return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  });
}
