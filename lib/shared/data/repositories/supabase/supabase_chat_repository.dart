import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../app_exception.dart';
import '../chat_repository.dart';
import 'supabase_guard.dart';
import 'supabase_notification_repository.dart';

/// Conversas via RPC; mensagens novas chegam pelo Realtime (tabela
/// `messages`, filtrada pela RLS de membros).
class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ChatThread>> threads(ChatKind kind) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('my_conversations', params: {'p_kind': _kinds[kind]});
    return list.map((t) => ChatThread.fromJson(t as Map<String, dynamic>)).toList();
  });

  @override
  Future<ChatThread> thread(String id) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('conversation', params: {'p_conversation_id': _id(id)});
    return ChatThread.fromJson(json);
  });

  @override
  Future<List<ChatMessage>> messages(String threadId) => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>(
      'conversation_messages',
      params: {'p_conversation_id': _id(threadId)},
    );
    return list.map(_message).toList();
  });

  @override
  Future<ChatMessage> send({
    required String threadId,
    required String authorName,
    required String text,
    String? sharedPostId,
  }) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'send_message',
      params: {
        'p_conversation_id': _id(threadId),
        'p_body': text.trim(),
        'p_shared_post_id': sharedPostId == null ? null : int.tryParse(sharedPostId),
      },
    );
    return _message(json);
  });

  @override
  Future<void> markRead(String threadId) =>
      supabaseGuard(() => _client.rpc<void>('mark_conversation_read', params: {'p_conversation_id': _id(threadId)}));

  @override
  Future<ChatThread> openWith(AppUser user) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('open_conversation', params: {'p_profile_id': user.id});
    return ChatThread.fromJson(json);
  });

  @override
  Stream<ChatMessage> incoming(String threadId) => realtimeInserts(
    _client,
    table: 'messages',
    filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: _id(threadId)),
  ).asyncMap(_messageById).where((m) => m != null).cast<ChatMessage>();

  @override
  Stream<void> inbox() => realtimeInserts(_client, table: 'messages').map((_) {});

  @override
  Future<int> unreadCount() => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('unread_counts');
    return (json['messages'] as num).toInt();
  });

  /// O Realtime entrega a linha crua; o RPC devolve no formato do app.
  Future<ChatMessage?> _messageById(Map<String, dynamic> row) async {
    try {
      final json = await _client.rpc<Map<String, dynamic>?>('message_by_id', params: {'p_message_id': row['id']});
      return json == null ? null : _message(json);
    } catch (_) {
      return null;
    }
  }

  ChatMessage _message(dynamic json) => ChatMessage.fromJson(json as Map<String, dynamic>);

  static const _kinds = {ChatKind.person: 'person', ChatKind.community: 'community', ChatKind.company: 'company'};

  int _id(String id) {
    final parsed = int.tryParse(id);
    if (parsed == null) throw const AppException('Conversa não encontrada.');
    return parsed;
  }
}
