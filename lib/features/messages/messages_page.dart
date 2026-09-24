import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'messages_cubit.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  static Widget route(BuildContext context) => BlocProvider(
    create: (context) => MessagesCubit(context.read<ChatRepository>())..load(),
    child: const MessagesPage(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessagesCubit, MessagesState>(
      builder: (context, state) {
        final cubit = context.read<MessagesCubit>();
        final q = state.query.toLowerCase();
        final threads = state.threads.where((t) => t.name.toLowerCase().contains(q)).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Mensagens')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: SegmentedButton<ChatKind>(
                  segments: [for (final k in ChatKind.values) ButtonSegment(value: k, label: Text(k.label))],
                  selected: {state.kind},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => cubit.selectKind(s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: cubit.search,
                  decoration: const InputDecoration(hintText: 'Pesquisar', prefixIcon: Icon(Icons.search_rounded)),
                ),
              ),
              Expanded(
                child: AsyncBody(
                  status: state.status,
                  builder: (context) => threads.isEmpty
                      ? const EmptyState(message: 'Nenhuma conversa por aqui.', icon: Icons.chat_bubble_outline)
                      : RefreshIndicator(
                          onRefresh: cubit.load,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(top: 8, bottom: 100),
                            itemCount: threads.length,
                            separatorBuilder: (_, _) => const Divider(indent: 84, height: 1),
                            itemBuilder: (context, i) => _ThreadTile(thread: threads[i]),
                          ),
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

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: () async {
        await context.push(AppRoutes.chat(thread.id));
        if (context.mounted) context.read<MessagesCubit>().load();
      },
      leading: Stack(
        children: [
          UserAvatar(name: thread.name, size: 48),
          if (thread.online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        thread.name,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
      subtitle: Text(thread.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Formatters.relative(thread.updatedAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          if (thread.unread > 0)
            CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.orange,
              child: Text('${thread.unread}', style: const TextStyle(fontSize: 11, color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
