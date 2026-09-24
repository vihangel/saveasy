import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/widgets/widgets.dart';

/// "Menu 1" do Figma.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.userOrNull);
    if (user == null) return const SizedBox.shrink();

    void open(String route) {
      Navigator.pop(context);
      context.push(route);
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png', width: 36),
                  const SizedBox(width: 8),
                  Text('SavEasy', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.profile);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    UserAvatar(name: user.name, imageUrl: user.avatarUrl, size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'LV ${user.level}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CoinChip(coins: user.coins),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Item(
              icon: Icons.home_rounded,
              label: 'Tela Inicial',
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.home);
              },
            ),
            _Item(icon: Icons.account_balance_wallet_rounded, label: 'Carteira', onTap: () => open(AppRoutes.wallet)),
            _Item(icon: Icons.emoji_events_rounded, label: 'Conquistas', onTap: () => open(AppRoutes.achievements)),
            _Item(icon: Icons.card_giftcard_rounded, label: 'Recompensas', onTap: () => open(AppRoutes.rewards)),
            _Item(icon: Icons.storefront_rounded, label: 'Loja', onTap: () => open(AppRoutes.store)),
            _Item(icon: Icons.settings_rounded, label: 'Configurações', onTap: () => open(AppRoutes.editProfile)),
            const Spacer(),
            _Item(
              icon: Icons.logout_rounded,
              label: 'Sair',
              color: AppColors.danger,
              onTap: () {
                Navigator.pop(context);
                context.read<SessionCubit>().logout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, required this.onTap, this.color = AppColors.text});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: color == AppColors.text ? AppColors.primary : color),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      onTap: onTap,
    );
  }
}
