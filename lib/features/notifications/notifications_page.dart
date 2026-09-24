import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'notifications_cubit.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static Widget route(BuildContext context) => BlocProvider(
    create: (context) => NotificationsCubit(context.read<NotificationRepository>())..load(),
    child: const NotificationsPage(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificações'),
            actions: [
              if (state.items.any((n) => !n.read))
                TextButton(onPressed: cubit.markAllRead, child: const Text('Ler todas')),
            ],
          ),
          body: AsyncBody(
            status: state.status,
            builder: (context) => state.items.isEmpty
                ? const EmptyState(message: 'Você não tem notificações.', icon: Icons.notifications_none_rounded)
                : RefreshIndicator(
                    onRefresh: cubit.load,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: state.items.length,
                      itemBuilder: (context, i) {
                        final n = state.items[i];
                        return ListTile(
                          tileColor: n.read ? null : AppColors.primaryLight.withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                            child: const Icon(Icons.event_note_rounded, color: AppColors.orange),
                          ),
                          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(n.body),
                          trailing: Text(
                            Formatters.relative(n.date),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          onTap: n.postId == null ? null : () => context.push(AppRoutes.post(n.postId!)),
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }
}
