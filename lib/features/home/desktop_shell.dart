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
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';

/// Estrutura do app logado em tablet e desktop: menu lateral fixo e o
/// conteúdo ao lado, tudo dentro de um contêiner centralizado de largura
/// máxima (em monitores largos o app não "espalha" pela tela).
///
/// No celular (compacto) devolve o [child] como está: lá vale a barra
/// inferior do `HomeShell`.
class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key, required this.child});

  final Widget child;

  /// Largura máxima do app inteiro (menu + conteúdo + coluna lateral).
  static const maxWidth = 1360.0;
  static const _background = Color(0xFFF4F5FA);

  static Widget route(BuildContext context, Widget child) => BlocProvider(
    create: (context) => BadgesCubit(context.read<ChatRepository>(), context.read<NotificationRepository>()),
    child: DesktopShell(child: child),
  );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionCubit>().state.userOrNull;
    if (context.isCompact || user == null) return child;
    final expanded = context.isExpanded;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border.symmetric(vertical: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: expanded ? 256 : 84,
                    child: _SideMenu(user: user, expanded: expanded),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(
                    child: Theme(data: _contentTheme(Theme.of(context)), child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Cabeçalhos das telas no desktop: título alinhado à esquerda, maior e com
  /// uma linha separando do conteúdo (no celular continuam centralizados).
  static ThemeData _contentTheme(ThemeData base) => base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      centerTitle: false,
      toolbarHeight: 68,
      titleSpacing: 24,
      backgroundColor: Colors.white,
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
      titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(fontSize: 22),
    ),
  );
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({required this.user, required this.expanded});

  final AppUser user;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final badges = context.watch<BadgesCubit>().state;

    Widget item(IconData icon, IconData selectedIcon, String label, String route, {int count = 0}) => _MenuItem(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      count: count,
      expanded: expanded,
      selected: path == route || path.startsWith('$route/'),
      onTap: () => context.go(route),
    );

    Widget heading(String text) => expanded
        ? Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          )
        : const Divider(indent: 20, endIndent: 20, height: 32, color: AppColors.border);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              // Marca.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: expanded ? 24 : 0, vertical: 4),
                child: Row(
                  mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo.png', width: 36),
                    if (expanded) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Save Easy',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Criar publicação.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 0),
                child: expanded
                    ? FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => context.push(AppRoutes.create),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Criar publicação'),
                      )
                    : Center(
                        child: IconButton.filled(
                          tooltip: 'Criar publicação',
                          style: IconButton.styleFrom(backgroundColor: AppColors.orange, fixedSize: const Size(48, 48)),
                          onPressed: () => context.push(AppRoutes.create),
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              item(Icons.home_outlined, Icons.home_rounded, 'Início', AppRoutes.home),
              item(
                Icons.chat_bubble_outline_rounded,
                Icons.chat_bubble_rounded,
                'Mensagens',
                AppRoutes.messages,
                count: badges.messages,
              ),
              item(
                Icons.notifications_outlined,
                Icons.notifications_rounded,
                'Notificações',
                AppRoutes.notifications,
                count: badges.notifications,
              ),
              item(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil', AppRoutes.profile),
              heading('Sua conta'),
              item(
                Icons.account_balance_wallet_outlined,
                Icons.account_balance_wallet_rounded,
                'Carteira',
                AppRoutes.wallet,
              ),
              item(Icons.storefront_outlined, Icons.storefront_rounded, 'Loja', AppRoutes.store),
              item(Icons.card_giftcard_outlined, Icons.card_giftcard_rounded, 'Recompensas', AppRoutes.rewards),
              item(Icons.emoji_events_outlined, Icons.emoji_events_rounded, 'Conquistas', AppRoutes.achievements),
              item(Icons.bookmark_outline_rounded, Icons.bookmark_rounded, 'Salvos', AppRoutes.saved),
              item(Icons.group_add_outlined, Icons.group_add_rounded, 'Convide amigos', AppRoutes.invite),
              if (user.accountType != AccountType.personal || user.isStaff) heading('Gestão'),
              if (user.accountType != AccountType.personal) ...[
                item(Icons.campaign_outlined, Icons.campaign_rounded, 'Anúncios', AppRoutes.ads),
                item(Icons.account_balance_outlined, Icons.account_balance_rounded, 'Financeiro', AppRoutes.finance),
              ],
              if (user.isStaff)
                item(
                  Icons.admin_panel_settings_outlined,
                  Icons.admin_panel_settings_rounded,
                  'Painel da equipe',
                  AppRoutes.admin,
                ),
              heading('Mais'),
              item(Icons.public_outlined, Icons.public_rounded, 'Transparência', AppRoutes.transparency),
              item(Icons.settings_outlined, Icons.settings_rounded, 'Configurações', AppRoutes.settings),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        _UserCard(user: user, expanded: expanded),
      ],
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
    this.count = 0,
  });

  final IconData icon, selectedIcon;
  final String label;
  final bool selected, expanded;
  final VoidCallback onTap;
  final int count;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color = selected ? AppColors.primary : AppColors.text;
    final icon = Badge(
      isLabelVisible: widget.count > 0,
      backgroundColor: AppColors.orange,
      label: Text(widget.count > 99 ? '99+' : '${widget.count}'),
      child: Icon(selected ? widget.selectedIcon : widget.icon, color: color, size: 22),
    );
    final background = selected ? AppColors.primaryLight : (_hover ? AppColors.surface : Colors.transparent);

    final tile = Semantics(
      button: true,
      selected: selected,
      label: widget.count > 0 ? '${widget.label}, ${widget.count} não lidas' : widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 46,
            padding: EdgeInsets.symmetric(horizontal: widget.expanded ? 14 : 0),
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
            child: widget.expanded
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: color,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(child: icon),
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.expanded ? 12 : 14, vertical: 2),
      child: widget.expanded ? tile : Tooltip(message: widget.label, child: tile),
    );
  }
}

/// Rodapé do menu: quem está logado, nível e moedas. Leva ao perfil.
class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.expanded});

  final AppUser user;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final avatar = UserAvatar(name: user.name, imageUrl: user.avatarUrl, size: 40);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => context.go(AppRoutes.profile),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 0, vertical: 16),
          child: expanded
              ? Row(
                  children: [
                    avatar,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                          Text(
                            'Nível ${user.level} · ${Formatters.number(user.coins)} moedas',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Tooltip(
                  message: user.name,
                  child: Center(child: avatar),
                ),
        ),
      ),
    );
  }
}
