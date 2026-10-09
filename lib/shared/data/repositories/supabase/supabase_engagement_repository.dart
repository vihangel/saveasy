import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../app_exception.dart';
import '../engagement_repository.dart';
import 'supabase_guard.dart';

/// Extras de publicação via RPC (supabase/migrations/*_gamification.sql).
class SupabaseEngagementRepository implements EngagementRepository {
  SupabaseEngagementRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PostExtras> extras(String postId) => supabaseGuard(() async {
    final id = int.tryParse(postId);
    if (id == null) return const PostExtras();
    final json = await _client.rpc<Map<String, dynamic>>('post_extras', params: {'p_post_id': id});
    return PostExtras.fromJson(json);
  });

  @override
  Future<List<Participant>> participants(String postId) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('post_participants', params: {'p_post_id': _id(postId)});
    return _participants(list);
  });

  @override
  Future<List<Participant>> checkIn(String postId, {String? profileId, String? code, bool attended = true}) =>
      supabaseGuard(() async {
        final list = await _client.rpc<List<dynamic>>(
          'check_in',
          params: {'p_post_id': _id(postId), 'p_profile_id': profileId, 'p_code': code, 'p_attended': attended},
        );
        return _participants(list);
      });

  @override
  Future<List<PostPhoto>> addPhoto(String postId, {required String imageUrl, String caption = ''}) =>
      supabaseGuard(() async {
        final list = await _client.rpc<List<dynamic>>(
          'add_post_photo',
          params: {'p_post_id': _id(postId), 'p_image_url': imageUrl, 'p_caption': caption},
        );
        return _photos(list);
      });

  @override
  Future<void> deletePhoto(String photoId) =>
      supabaseGuard(() => _client.rpc<void>('delete_post_photo', params: {'p_photo_id': _id(photoId)}));

  @override
  Future<List<PostUpdate>> addUpdate(String postId, {required String body, String? imageUrl}) =>
      supabaseGuard(() async {
        final list = await _client.rpc<List<dynamic>>(
          'add_post_update',
          params: {'p_post_id': _id(postId), 'p_body': body.trim(), 'p_image_url': imageUrl},
        );
        return list.map((u) => PostUpdate.fromJson(u as Map<String, dynamic>)).toList();
      });

  @override
  Future<ItemRequest> requestItem(String postId, {String message = ''}) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'request_item',
      params: {'p_post_id': _id(postId), 'p_message': message.trim()},
    );
    return ItemRequest.fromJson(json);
  });

  @override
  Future<ItemRequest> updateItemRequest(String requestId, ItemRequestStatus status) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'update_item_request',
      params: {'p_request_id': _id(requestId), 'p_status': status.name},
    );
    return ItemRequest.fromJson(json);
  });

  @override
  Future<List<ItemRequest>> itemRequests(String postId) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('item_requests_for_post', params: {'p_post_id': _id(postId)});
    return list.map((r) => ItemRequest.fromJson(r as Map<String, dynamic>)).toList();
  });

  @override
  Future<List<AppUser>> setMentions(String postId, List<String> profileIds) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>(
      'set_post_mentions',
      params: {'p_post_id': _id(postId), 'p_profile_ids': profileIds},
    );
    return list.map((u) => AppUser.fromJson(u as Map<String, dynamic>)).toList();
  });

  @override
  Future<List<PostPhoto>> album(String profileId) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('profile_album', params: {'p_profile_id': profileId});
    return _photos(list);
  });

  List<Participant> _participants(List<dynamic> list) =>
      list.map((p) => Participant.fromJson(p as Map<String, dynamic>)).toList();

  List<PostPhoto> _photos(List<dynamic> list) =>
      list.map((p) => PostPhoto.fromJson(p as Map<String, dynamic>)).toList();

  int _id(String id) {
    final parsed = int.tryParse(id);
    if (parsed == null) throw const AppException('Item não encontrado.');
    return parsed;
  }
}
