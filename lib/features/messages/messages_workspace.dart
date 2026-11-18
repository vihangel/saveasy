import 'package:flutter/material.dart';

import '../../app/breakpoints.dart';
import '../../shared/widgets/widgets.dart';
import '../chat/chat_page.dart';
import 'messages_page.dart';

class MessagesWorkspace extends StatefulWidget {
  const MessagesWorkspace({super.key, this.threadId});
  final String? threadId;
  @override
  State<MessagesWorkspace> createState() => _MessagesWorkspaceState();
}

class _MessagesWorkspaceState extends State<MessagesWorkspace> {
  final _conversationKey = GlobalKey();
  final _listKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final id = widget.threadId;
    final list = KeyedSubtree(key: _listKey, child: MessagesPage.route(context));
    final conversation = id == null
        ? null
        : KeyedSubtree(
            key: _conversationKey,
            child: KeyedSubtree(key: ValueKey(id), child: ChatPage.route(context, id)),
          );
    if (!context.isExpanded) return id == null ? list : conversation!;
    return Row(
      children: [
        SizedBox(width: 380, child: list),
        const VerticalDivider(width: 1),
        Expanded(
          child:
              conversation ??
              const EmptyState(
                message: 'Escolha uma conversa ao lado para ler e responder.',
                icon: Icons.forum_outlined,
              ),
        ),
      ],
    );
  }
}
