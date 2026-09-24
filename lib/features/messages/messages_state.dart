part of 'messages_cubit.dart';

@freezed
abstract class MessagesState with _$MessagesState {
  const factory MessagesState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(ChatKind.person) ChatKind kind,
    @Default(<ChatThread>[]) List<ChatThread> threads,
    @Default('') String query,
  }) = _MessagesState;
}
