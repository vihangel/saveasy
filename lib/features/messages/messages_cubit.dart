import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/view_status.dart';

part 'messages_cubit.freezed.dart';
part 'messages_state.dart';

/// Mensagens - Pessoal / Comunidade / Empresas. Recarrega quando chega
/// mensagem nova em qualquer conversa.
class MessagesCubit extends Cubit<MessagesState> {
  MessagesCubit(this._chats) : super(const MessagesState()) {
    _inbox = _chats.inbox().listen((_) => load());
  }

  final ChatRepository _chats;
  late final StreamSubscription<void> _inbox;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(status: state.threads.isEmpty ? ViewStatus.loading : state.status));
    try {
      final threads = await _chats.threads(state.kind);
      if (!isClosed) emit(state.copyWith(status: ViewStatus.success, threads: threads));
    } on AppException {
      if (!isClosed) emit(state.copyWith(status: ViewStatus.failure));
    }
  }

  void selectKind(ChatKind kind) {
    emit(state.copyWith(kind: kind, threads: []));
    load();
  }

  void search(String query) => emit(state.copyWith(query: query));

  @override
  Future<void> close() async {
    await _inbox.cancel();
    return super.close();
  }
}
