import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'chat_cubit.freezed.dart';
part 'chat_state.dart';

/// Conversa - Pessoal / Comunidade. Mensagens novas chegam em tempo real.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this.threadId, this._chats, this._posts, this._session) : super(const ChatState());

  final String threadId;
  final ChatRepository _chats;
  final PostRepository _posts;
  final SessionCubit _session;
  StreamSubscription<ChatMessage>? _incoming;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    try {
      final (thread, messages) = await (_chats.thread(threadId), _chats.messages(threadId)).wait;
      emit(
        state.copyWith(
          status: ViewStatus.success,
          thread: thread,
          messages: messages,
          sharedPosts: await _loadPosts(messages),
        ),
      );
    } on ParallelWaitError {
      return emit(state.copyWith(status: ViewStatus.failure));
    } on AppException {
      return emit(state.copyWith(status: ViewStatus.failure));
    }
    _incoming ??= _chats.incoming(threadId).listen(_onIncoming);
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    final message = await _chats.send(threadId: threadId, authorName: _session.user.name, text: text);
    _add(message);
  }

  Future<void> _onIncoming(ChatMessage message) async {
    if (isClosed) return;
    _add(message);
    if (!message.fromMe) await _chats.markRead(threadId);
  }

  /// A minha mensagem chega duas vezes (resposta do envio e Realtime).
  void _add(ChatMessage message) {
    if (isClosed || state.messages.any((m) => m.id == message.id)) return;
    emit(state.copyWith(messages: [...state.messages, message]));
  }

  Future<Map<String, Post>> _loadPosts(List<ChatMessage> messages) async {
    final ids = messages.map((m) => m.sharedPostId).whereType<String>().toSet();
    final posts = <String, Post>{};
    for (final id in ids) {
      try {
        posts[id] = await _posts.getById(id);
      } on AppException {
        // Publicação excluída: a mensagem aparece sem o card.
      }
    }
    return posts;
  }

  @override
  Future<void> close() async {
    await _incoming?.cancel();
    return super.close();
  }
}
