import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../notification_repository.dart';
import 'supabase_guard.dart';

/// Notificações geradas por triggers no banco; novas chegam pelo Realtime.
class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AppNotification>> all() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('my_notifications');
    return list.map((n) => AppNotification.fromJson(n as Map<String, dynamic>)).toList();
  });

  @override
  Future<void> markRead(String id) => supabaseGuard(
    () => _client.rpc<void>(
      'mark_notifications_read',
      params: {
        'p_ids': [int.parse(id)],
      },
    ),
  );

  @override
  Future<void> markAllRead() => supabaseGuard(() => _client.rpc<void>('mark_notifications_read'));

  @override
  Future<int> unreadCount() => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('unread_counts');
    return (json['notifications'] as num).toInt();
  });

  @override
  Stream<void> changes() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return realtimeInserts(
      _client,
      table: 'notifications',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'recipient_id', value: userId),
    ).map((_) {});
  }
}

/// Stream de inserts de uma tabela via Realtime. O canal abre ao escutar e
/// fecha ao cancelar. A RLS da tabela decide quais linhas chegam.
Stream<Map<String, dynamic>> realtimeInserts(
  SupabaseClient client, {
  required String table,
  PostgresChangeFilter? filter,
}) {
  RealtimeChannel? channel;
  late final StreamController<Map<String, dynamic>> controller;
  controller = StreamController<Map<String, dynamic>>(
    onListen: () {
      channel = client
          .channel('$table:${filter?.value ?? 'all'}:${DateTime.now().microsecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: table,
            filter: filter,
            callback: (payload) => controller.add(payload.newRecord),
          )
          .subscribe();
    },
    onCancel: () async {
      final c = channel;
      channel = null;
      if (c != null) await client.removeChannel(c);
    },
  );
  return controller.stream;
}
