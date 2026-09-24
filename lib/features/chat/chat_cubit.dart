import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'chat_cubit.freezed.dart';
part 'chat_state.dart';

/// Conversa - Pessoal / Comunidade.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this.threadId, this._chats, this._posts, this._session) : super(const ChatState());

  final String threadId;
  final ChatRepository _chats;
  final PostRepository _posts;
  final SessionCubit _session;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    final (thread, messages) = await (_chats.thread(threadId), _chats.messages(threadId)).wait;
    final ids = messages.map((m) => m.sharedPostId).whereType<String>().toSet();
    final posts = await Future.wait(ids.map(_posts.getById));
    emit(
      state.copyWith(
        status: ViewStatus.success,
        thread: thread,
        messages: messages,
        sharedPosts: {for (final p in posts) p.id: p},
      ),
    );
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    final message = await _chats.send(threadId: threadId, authorName: _session.user.name, text: text);
    emit(state.copyWith(messages: [...state.messages, message]));
  }
}
