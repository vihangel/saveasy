import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
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

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    try {
      await context.read<ChatCubit>().send(text);
    } on AppException catch (e) {
      if (!mounted) return;
      _input.text = text;
      context.showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final thread = state.thread;
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(fallback: AppRoutes.messages),
            actions: [
              if (thread?.peerId != null && !(thread?.isGroup ?? true))
                PopupMenuButton<String>(
                  onSelected: (action) async {
                    final peer = thread!.peerId!;
                    if (action == 'report') return showReportSheet(context, ReportTarget.profile, peer);
                    try {
                      final (blocked, _) = await context.read<ModerationRepository>().toggleBlock(peer);
                      if (context.mounted) context.showMessage(blocked ? 'Perfil bloqueado.' : 'Perfil desbloqueado.');
                    } on AppException catch (e) {
                      if (context.mounted) context.showMessage(e.message, error: true);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'block', child: Text('Bloquear / desbloquear')),
                    PopupMenuItem(value: 'report', child: Text('Denunciar')),
                  ],
                ),
            ],
            centerTitle: false,
            titleSpacing: 0,
            title: thread == null
                ? null
                : Row(
                    children: [
                      GestureDetector(
                        onTap: thread.peerId == null ? null : () => context.push(AppRoutes.user(thread.peerId!)),
                        child: UserAvatar(name: thread.name, imageUrl: thread.avatarUrl, size: 36),
                      ),
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
                                  : thread.online
                                  ? 'Online agora'
                                  : (thread.peerUsername == null ? 'Offline' : '@${thread.peerUsername}'),
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
                  onRetry: context.read<ChatCubit>().load,
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
