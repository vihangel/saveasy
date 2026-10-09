import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../app_exception.dart';
import '../story_repository.dart';
import 'supabase_guard.dart';

/// Stories via RPC (supabase/migrations/*_stories_chat_notifications.sql).
class SupabaseStoryRepository implements StoryRepository {
  SupabaseStoryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Story>> stories() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('stories_tray');
    return list.map((s) => Story.fromJson(s as Map<String, dynamic>)).toList();
  });

  @override
  Future<AppUser?> view(String storyId, {required String userId}) => supabaseGuard(() async {
    final id = int.tryParse(storyId);
    if (id == null) return null;
    final json = await _client.rpc<Map<String, dynamic>?>('view_story', params: {'p_story_id': id});
    return json == null ? null : AppUser.fromJson(json);
  });

  @override
  Future<AppUser> create({required AppUser author, required PostType type, required String text, String? imageUrl}) =>
      supabaseGuard(() async {
        final draft = Story(
          id: '',
          authorId: author.id,
          authorName: author.name,
          type: type,
          text: text.trim(),
          createdAt: DateTime.now(),
          imageUrl: imageUrl,
        ).toJson();
        final json = await _client.rpc<Map<String, dynamic>>(
          'create_story',
          params: {
            'p': {'type': draft['type'], 'text': draft['text'], 'imageUrl': imageUrl},
          },
        );
        return AppUser.fromJson(json['me'] as Map<String, dynamic>);
      });

  @override
  Future<void> delete(String storyId) => supabaseGuard(() async {
    final id = int.tryParse(storyId);
    if (id == null) throw const AppException('Story não encontrado.');
    await _client.rpc<void>('delete_story', params: {'p_story_id': id});
  });
}
