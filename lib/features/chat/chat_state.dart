part of 'chat_cubit.dart';

@freezed
abstract class ChatState with _$ChatState {
  const factory ChatState({
    @Default(ViewStatus.initial) ViewStatus status,
    ChatThread? thread,
    @Default(<ChatMessage>[]) List<ChatMessage> messages,

    /// Publicações compartilhadas nas mensagens, por id.
    @Default(<String, Post>{}) Map<String, Post> sharedPosts,
  }) = _ChatState;
}
