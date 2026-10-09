import '../models/models.dart';

/// Conversas diretas e grupos de comunidade. Implementações:
/// [MockChatRepository] e [SupabaseChatRepository] (com Realtime).
abstract interface class ChatRepository {
  Future<List<ChatThread>> threads(ChatKind kind);

  Future<ChatThread> thread(String id);

  /// Mensagens em ordem cronológica. Abrir a conversa marca como lida.
  Future<List<ChatMessage>> messages(String threadId);

  Future<ChatMessage> send({
    required String threadId,
    required String authorName,
    required String text,
    String? sharedPostId,
  });

  Future<void> markRead(String threadId);

  /// Abre (ou cria) a conversa com um perfil. Comunidade abre o grupo dela.
  Future<ChatThread> openWith(AppUser user);

  /// Mensagens novas da conversa em tempo real (inclui as minhas).
  Stream<ChatMessage> incoming(String threadId);

  /// Avisa quando chega mensagem em qualquer conversa minha.
  Stream<void> inbox();

  Future<int> unreadCount();
}
