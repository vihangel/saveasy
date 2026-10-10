import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/breakpoints.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/badges_cubit.dart';
import '../../shared/notifiers/session_cubit.dart';

/// Persistent navigation around both tabs and pushed detail routes.
class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key, required this.child});
  final Widget child;

  static Widget route(BuildContext context, Widget child) => BlocProvider(
    create: (context) => BadgesCubit(context.read<ChatRepository>(), context.read<NotificationRepository>()),
    child: DesktopShell(child: child),
  );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionCubit>().state.userOrNull;
    if (context.isCompact || user == null) return child;
    final expanded = context.isExpanded;
    final path = GoRouterState.of(context).uri.path;
    final badges = context.watch<BadgesCubit>().state;
    Widget item(IconData icon, String label, String route, {int count = 0}) {
      final selected = path == route || path.startsWith('$route/');
      final symbol = Badge(isLabelVisible: count > 0, label: Text(count > 99 ? '99+' : '$count'), child: Icon(icon));
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: expanded
            ? ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                selected: selected,
                selectedTileColor: AppColors.primaryLight,
                leading: symbol,
                title: Text(label),
                onTap: () => context.go(route),
              )
            : Tooltip(
                message: label,
                child: IconButton.filledTonal(isSelected: selected, onPressed: () => context.go(route), icon: symbol),
              ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: expanded ? 232 : 76,
              child: Material(
                color: Colors.white,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/logo.png', width: 32),
                          if (expanded) ...[
                            const SizedBox(width: 12),
                            const Flexible(
                              child: Text(
                                'Save Easy',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: expanded
                          ? FilledButton.icon(
                              onPressed: () => context.push(AppRoutes.create),
                              icon: const Icon(Icons.add),
                              label: const Text('Criar'),
                            )
                          : IconButton.filled(
                              tooltip: 'Criar',
                              onPressed: () => context.push(AppRoutes.create),
                              icon: const Icon(Icons.add),
                            ),
                    ),
                    item(Icons.home_outlined, 'Início', AppRoutes.home),
                    item(Icons.chat_bubble_outline, 'Mensagens', AppRoutes.messages, count: badges.messages),
                    item(
                      Icons.notifications_outlined,
                      'Notificações',
                      AppRoutes.notifications,
                      count: badges.notifications,
                    ),
                    item(Icons.person_outline, 'Perfil', AppRoutes.profile),
                    const Divider(indent: 16, endIndent: 16, height: 32),
                    item(Icons.account_balance_wallet_outlined, 'Carteira', AppRoutes.wallet),
                    item(Icons.storefront_outlined, 'Loja', AppRoutes.store),
                    item(Icons.card_giftcard, 'Recompensas', AppRoutes.rewards),
                    item(Icons.emoji_events_outlined, 'Conquistas', AppRoutes.achievements),
                    item(Icons.bookmark_outline, 'Salvos', AppRoutes.saved),
                    item(Icons.group_add_outlined, 'Convide amigos', AppRoutes.invite),
                    if (user.accountType != AccountType.personal) ...[
                      item(Icons.campaign_outlined, 'Anúncios', AppRoutes.ads),
                      item(Icons.account_balance_outlined, 'Financeiro', AppRoutes.finance),
                    ],
                    if (user.isStaff) item(Icons.admin_panel_settings_outlined, 'Equipe', AppRoutes.admin),
                    item(Icons.settings_outlined, 'Configurações', AppRoutes.settings),
                    item(Icons.public, 'Transparência', AppRoutes.transparency),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
