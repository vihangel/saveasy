import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat.freezed.dart';
part 'chat.g.dart';

enum ChatKind {
  @JsonValue('person')
  person('Pessoas'),
  @JsonValue('community')
  community('Comunidades'),
  @JsonValue('company')
  company('Empresas');

  const ChatKind(this.label);

  final String label;
}

@freezed
abstract class ChatThread with _$ChatThread {
  const factory ChatThread({
    required String id,
    required String name,
    required ChatKind kind,
    required String lastMessage,
    required DateTime updatedAt,
    @Default(0) int unread,
    @Default(false) bool online,
    @Default(0) int members,
  }) = _ChatThread;

  factory ChatThread.fromJson(Map<String, dynamic> json) => _$ChatThreadFromJson(json);
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String threadId,
    required String authorName,
    required String text,
    required DateTime sentAt,
    @Default(false) bool fromMe,
    String? sharedPostId,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}
