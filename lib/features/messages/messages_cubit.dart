import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/view_status.dart';

part 'messages_cubit.freezed.dart';
part 'messages_state.dart';

/// Mensagens - Pessoal / Comunidade / Empresas.
class MessagesCubit extends Cubit<MessagesState> {
  MessagesCubit(this._chats) : super(const MessagesState());

  final ChatRepository _chats;

  Future<void> load() async {
    emit(state.copyWith(status: state.threads.isEmpty ? ViewStatus.loading : state.status));
    emit(state.copyWith(status: ViewStatus.success, threads: await _chats.threads(state.kind)));
  }

  void selectKind(ChatKind kind) {
    emit(state.copyWith(kind: kind, threads: []));
    load();
  }

  void search(String query) => emit(state.copyWith(query: query));
}
