import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import 'app_drawer.dart';

/// Estrutura principal com a barra inferior (Início, Mensagens, Criar,
/// Notificações e Perfil) e o menu lateral.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static final scaffoldKey = GlobalKey<ScaffoldState>();

  void _go(int index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      body: navigationShell,
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
            _NavItem(icon: Icons.home_rounded, label: 'Início', selected: index == 0, onTap: () => _go(0)),
            _NavItem(icon: Icons.chat_bubble_rounded, label: 'Mensagens', selected: index == 1, onTap: () => _go(1)),
            const Expanded(child: SizedBox()),
            _NavItem(
              icon: Icons.notifications_rounded,
              label: 'Notificações',
              selected: index == 2,
              onTap: () => _go(2),
            ),
            _NavItem(icon: Icons.person_rounded, label: 'Perfil', selected: index == 3, onTap: () => _go(3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

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
                Icon(icon, color: color),
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
