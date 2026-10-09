import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/badges_cubit.dart';
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
                TextButton(
                  onPressed: () async {
                    await cubit.markAllRead();
                    if (context.mounted) context.read<BadgesCubit>().refresh();
                  },
                  child: const Text('Ler todas'),
                ),
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
                          leading: _Leading(notification: n),
                          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: n.body.isEmpty ? null : Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Text(
                            Formatters.relative(n.date),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          onTap: () async {
                            final badges = context.read<BadgesCubit>();
                            await cubit.open(n);
                            badges.refresh();
                            if (!context.mounted) return;
                            if (n.postId != null) {
                              context.push(AppRoutes.post(n.postId!));
                            } else if (n.actorId != null) {
                              context.push(AppRoutes.user(n.actorId!));
                            }
                          },
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

/// Foto de quem gerou a notificação, ou um ícone pelo tipo.
class _Leading extends StatelessWidget {
  const _Leading({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    if (n.actorName != null && n.kind != NotificationKind.eventReminder) {
      return UserAvatar(name: n.actorName!, imageUrl: n.actorAvatarUrl, size: 40);
    }
    final icon = switch (n.kind) {
      NotificationKind.follow => Icons.person_add_alt_1_rounded,
      NotificationKind.comment || NotificationKind.reply => Icons.chat_bubble_outline_rounded,
      NotificationKind.participation => Icons.how_to_reg_rounded,
      NotificationKind.coinsReceived => Icons.monetization_on_rounded,
      NotificationKind.eventReminder => Icons.event_available_rounded,
      NotificationKind.system => Icons.event_note_rounded,
    };
    return CircleAvatar(
      backgroundColor: AppColors.orange.withValues(alpha: 0.15),
      child: Icon(icon, color: AppColors.orange),
    );
  }
}
