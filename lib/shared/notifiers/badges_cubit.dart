import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/repositories.dart';

/// Contadores de não lidas da barra inferior (mensagens e notificações).
/// Atualiza sozinho quando o Realtime avisa de algo novo.
class BadgesCubit extends Cubit<({int messages, int notifications})> {
  BadgesCubit(this._chats, this._notifications) : super((messages: 0, notifications: 0)) {
    _subscriptions = [_chats.inbox().listen((_) => refresh()), _notifications.changes().listen((_) => refresh())];
    refresh();
  }

  final ChatRepository _chats;
  final NotificationRepository _notifications;
  late final List<StreamSubscription<void>> _subscriptions;

  Future<void> refresh() async {
    try {
      final (messages, notifications) = await (_chats.unreadCount(), _notifications.unreadCount()).wait;
      if (!isClosed) emit((messages: messages, notifications: notifications));
    } catch (_) {
      // Contador é só indicativo: mantém o último valor se falhar.
    }
  }

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }
}
