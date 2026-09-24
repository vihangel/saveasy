import '../datasources/mock_database.dart';
import '../models/models.dart';

class ChatRepository {
  ChatRepository(this._db);

  final MockDatabase _db;

  Future<List<ChatThread>> threads(ChatKind kind) async {
    await _db.delay();
    return _db.chats.where((c) => c.kind == kind).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  int unreadCount() => _db.chats.fold(0, (sum, c) => sum + c.unread);

  Future<ChatThread> thread(String id) async => _db.chats.firstWhere((c) => c.id == id);

  Future<List<ChatMessage>> messages(String threadId) async {
    await _db.delay();
    _db.chats = [for (final c in _db.chats) c.id == threadId ? c.copyWith(unread: 0) : c];
    await _db.saveChats();
    return _db.messages.where((m) => m.threadId == threadId).toList()..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  Future<ChatMessage> send({
    required String threadId,
    required String authorName,
    required String text,
    String? sharedPostId,
  }) async {
    final message = ChatMessage(
      id: _db.newId('m'),
      threadId: threadId,
      authorName: authorName,
      text: text.trim(),
      sentAt: DateTime.now(),
      fromMe: true,
      sharedPostId: sharedPostId,
    );
    _db.messages = [..._db.messages, message];
    _db.chats = [
      for (final c in _db.chats)
        c.id == threadId ? c.copyWith(lastMessage: message.text, updatedAt: message.sentAt) : c,
    ];
    await Future.wait([_db.saveMessages(), _db.saveChats()]);
    return message;
  }

  /// Abre (ou cria) a conversa com um perfil.
  Future<ChatThread> openWith(AppUser user) async {
    final existing = _db.chats.where((c) => c.name == user.name).firstOrNull;
    if (existing != null) return existing;
    final thread = ChatThread(
      id: _db.newId('ch'),
      name: user.name,
      kind: switch (user.accountType) {
        AccountType.community => ChatKind.community,
        AccountType.business => ChatKind.company,
        _ => ChatKind.person,
      },
      lastMessage: '',
      updatedAt: DateTime.now(),
    );
    _db.chats = [..._db.chats, thread];
    await _db.saveChats();
    return thread;
  }
}
