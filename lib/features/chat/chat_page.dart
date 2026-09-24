import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'chat_cubit.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  static Widget route(BuildContext context, String threadId) => BlocProvider(
    create: (context) => ChatCubit(
      threadId,
      context.read<ChatRepository>(),
      context.read<PostRepository>(),
      context.read<SessionCubit>(),
    )..load(),
    child: const ChatPage(),
  );

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    context.read<ChatCubit>().send(_input.text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final thread = state.thread;
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            titleSpacing: 0,
            title: thread == null
                ? null
                : Row(
                    children: [
                      UserAvatar(name: thread.name, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thread.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              thread.kind == ChatKind.community
                                  ? '${Formatters.compact(thread.members)} participantes'
                                  : (thread.online ? 'Online agora' : 'Offline'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          body: Column(
            children: [
              Expanded(
                child: AsyncBody(
                  status: state.status,
                  builder: (context) => ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, i) {
                      final message = state.messages[state.messages.length - 1 - i];
                      return _Bubble(
                        message: message,
                        showAuthor: thread?.kind == ChatKind.community && !message.fromMe,
                        sharedPost: state.sharedPosts[message.sharedPostId],
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(hintText: 'Digite uma mensagem...'),
                        ),
                      ),
                      IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.showAuthor, this.sharedPost});

  final ChatMessage message;
  final bool showAuthor;
  final Post? sharedPost;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showAuthor)
                Text(
                  message.authorName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.orange),
                ),
              Text(message.text, style: TextStyle(color: mine ? Colors.white : AppColors.textDark)),
              if (sharedPost != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: 220,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: PostTile(post: sharedPost!, width: 204),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                Formatters.relative(message.sentAt),
                style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
