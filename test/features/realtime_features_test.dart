import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/features/chat/chat_cubit.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_database.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/data/models/models.dart';
import 'package:saveeasy2026/shared/data/repositories/repositories.dart';
import 'package:saveeasy2026/shared/notifiers/badges_cubit.dart';
import 'package:saveeasy2026/shared/notifiers/session_cubit.dart';

import '../helpers/test_database.dart';

/// Chat mock com um "Realtime" controlado pelo teste.
class _LiveChat extends MockChatRepository {
  _LiveChat(super.db);

  final live = StreamController<ChatMessage>.broadcast();
  final inboxEvents = StreamController<void>.broadcast();
  int reads = 0;

  @override
  Stream<ChatMessage> incoming(String threadId) => live.stream;

  @override
  Stream<void> inbox() => inboxEvents.stream;

  @override
  Future<void> markRead(String threadId) async => reads++;
}

void main() {
  late MockDatabase db;
  late SessionCubit session;

  setUp(() async {
    final (database, storage) = await createTestDatabase();
    db = database;
    final auth = MockAuthRepository(db, storage);
    await auth.login(MockSeed.demoEmail, MockSeed.demoPassword);
    session = SessionCubit(auth);
    await session.restore();
  });

  test('story de propaganda dá moedas só na primeira visualização', () async {
    final stories = MockStoryRepository(db);
    final before = db.userById(MockSeed.demoUserId).coins;

    final first = await stories.view('s_4', userId: MockSeed.demoUserId);
    final second = await stories.view('s_4', userId: MockSeed.demoUserId);

    expect(first?.coins, before + 20);
    expect(second, isNull);
    expect(db.stories.firstWhere((s) => s.id == 's_4').seen, isTrue);
  });

  test('mensagem que chega pelo Realtime entra uma vez e marca como lida', () async {
    final chat = _LiveChat(db);
    final cubit = ChatCubit('ch_whinderson', chat, MockPostRepository(db), session);
    await cubit.load();
    final count = cubit.state.messages.length;

    final incoming = ChatMessage(
      id: 'rt_1',
      threadId: 'ch_whinderson',
      authorName: 'Whinderson',
      text: 'Chegou ao vivo',
      sentAt: DateTime.now(),
    );
    chat.live
      ..add(incoming)
      ..add(incoming);
    await pumpEventQueue();

    expect(cubit.state.messages.length, count + 1);
    expect(cubit.state.messages.last.text, 'Chegou ao vivo');
    expect(chat.reads, greaterThan(0));

    // A minha mensagem volta pelo Realtime e não duplica.
    await cubit.send('Oi!');
    chat.live.add(cubit.state.messages.last);
    await pumpEventQueue();
    expect(cubit.state.messages.where((m) => m.text == 'Oi!').length, 1);
    await cubit.close();
  });

  test('contadores da barra atualizam quando chega mensagem', () async {
    final chat = _LiveChat(db);
    final badges = BadgesCubit(chat, MockNotificationRepository(db));
    await pumpEventQueue();
    final unread = badges.state.messages;
    expect(unread, greaterThan(0));

    await chat.messages('ch_whinderson');
    chat.inboxEvents.add(null);
    await pumpEventQueue();

    expect(badges.state.messages, lessThan(unread));
    await badges.close();
  });
}
