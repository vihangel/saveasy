import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/breakpoints.dart';
import '../../app/theme.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/badges_cubit.dart';
import '../../shared/widgets/widgets.dart';
import 'app_drawer.dart';

/// Estrutura principal com a barra inferior (Início, Mensagens, Criar,
/// Notificações e Perfil) e o menu lateral.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static Widget route(BuildContext context, StatefulNavigationShell shell) => BlocProvider(
    create: (context) => BadgesCubit(context.read<ChatRepository>(), context.read<NotificationRepository>()),
    child: HomeShell(navigationShell: shell),
  );

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    final badges = context.watch<BadgesCubit>().state;
    void go(int i) {
      navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
      context.read<BadgesCubit>().refresh();
    }

    if (!context.isCompact) return navigationShell;

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(child: navigationShell),
          const AdBar(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.create),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 12,
        shadowColor: Colors.black26,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'Início', selected: index == 0, onTap: () => go(0)),
            _NavItem(
              icon: Icons.chat_bubble_rounded,
              label: 'Mensagens',
              selected: index == 1,
              badge: badges.messages,
              onTap: () => go(1),
            ),
            const Expanded(child: SizedBox()),
            _NavItem(
              icon: Icons.notifications_rounded,
              label: 'Notificações',
              selected: index == 2,
              badge: badges.notifications,
              onTap: () => go(2),
            ),
            _NavItem(icon: Icons.person_rounded, label: 'Perfil', selected: index == 3, onTap: () => go(3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Quantidade de não lidas (0 esconde o selo).
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        // FittedBox reduz o item quando a fonte do sistema está grande,
        // em vez de estourar a altura fixa da barra.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  isLabelVisible: badge > 0,
                  backgroundColor: AppColors.orange,
                  label: Text(badge > 99 ? '99+' : '$badge'),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
