import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/app_icons.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import '../activity/activity_page.dart';
import 'profile_cubit.dart';

/// Perfil / Perfil Pessoal / Influencer / Comunidade / Empresa, com as abas
/// Publicações, Currículo de Ações e Álbum de boas ações.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.isTab = false});

  /// Aba "Perfil" da barra inferior: não mostra o voltar.
  final bool isTab;

  static Widget route(BuildContext context, String userId, {bool isTab = false}) => BlocProvider(
    key: ValueKey(userId),
    create: (context) => ProfileCubit(
      userId: userId,
      users: context.read<UserRepository>(),
      posts: context.read<PostRepository>(),
      gamification: context.read<GamificationRepository>(),
      wallet: context.read<WalletRepository>(),
      session: context.read<SessionCubit>(),
    )..load(),
    child: ProfilePage(isTab: isTab),
  );

  @override
  Widget build(BuildContext context) {
    // Recarrega quando o usuário logado muda (ex.: editou o perfil, ganhou XP).
    return BlocListener<SessionCubit, SessionState>(
      listener: (context, _) => context.read<ProfileCubit>().load(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => Scaffold(
          body: AsyncBody(
            status: state.status,
            error: state.error,
            builder: (context) => _Body(state: state, showBack: !isTab),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.showBack});

  final ProfileState state;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final user = state.user!;
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: _Header(state: state, showBack: showBack),
          ),
          const SliverToBoxAdapter(
            child: TabBar(
              tabs: [
                Tab(text: 'Publicações'),
                Tab(text: 'Currículo'),
                Tab(text: 'Álbum'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          children: [
            state.posts.isEmpty
                ? const EmptyState(message: 'Nenhuma publicação ainda.')
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: state.posts.length,
                    itemBuilder: (context, i) => PostCard(post: state.posts[i]),
                  ),
            ActionResumeView(profileId: user.id),
            PhotoAlbumView(profileId: user.id),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.showBack});

  final ProfileState state;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final user = state.user!;
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(gradient: LinearGradient(colors: _coverColors(state.cover))),
                // Capa do perfil: foto própria > capa de recompensa > gradiente da marca.
                child: user.coverUrl != null
                    ? AppImage(reference: user.coverUrl!, height: 150, width: double.infinity)
                    : state.cover == null
                    ? null
                    : Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: Icon(AppIcons.byKey(state.cover!.icon), size: 96, color: Colors.white24),
                        ),
                      ),
              ),
              SafeArea(
                child: Row(
                  children: [
                    if (showBack) const AppBackButton(color: Colors.white),
                    const Spacer(),
                    if (state.isMe)
                      IconButton(
                        tooltip: 'Configurações',
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: () => context.push(AppRoutes.settings),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: UserAvatar(name: user.name, imageUrl: user.avatarUrl, size: 104),
                      ),
                      Positioned(
                        right: -4,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            'LV ${user.level}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 24),
            Flexible(
              child: Text(
                user.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleLarge,
              ),
            ),
            const SizedBox(width: 6),
            Icon(AppIcons.accountType(user.accountType), size: 18, color: AppColors.primary),
            const SizedBox(width: 24),
          ],
        ),
        Text(
          '@${user.username} · ${user.accountType.label}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        if (state.title != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.title!.name,
              style: const TextStyle(fontSize: 13, color: AppColors.orange, fontWeight: FontWeight.w600),
            ),
          ),
        if (user.bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
            child: Text(user.bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
          ),
        if (state.badges.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final badge in state.badges)
                  Tooltip(
                    message: badge.name,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(AppIcons.byKey(badge.icon), size: 18, color: AppColors.primary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _Stat(value: Formatters.compact(user.postsCount), label: 'Publicações'),
              _Stat(
                value: Formatters.compact(user.followers),
                label: 'Seguidores',
                onTap: () => context.push(AppRoutes.follows(user.id)),
              ),
              _Stat(
                value: Formatters.compact(user.following),
                label: 'Seguindo',
                onTap: () => context.push(AppRoutes.follows(user.id, following: true)),
              ),
              if (user.rating > 0)
                _Stat(value: user.rating.toStringAsFixed(1), label: 'Avaliação', icon: Icons.star_rounded),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: state.isMe ? _MyActions(user: user) : _VisitorActions(user: user),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.icon, this.onTap});

  final String value;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            FittedBox(
              child: Row(
                children: [
                  if (icon != null) Icon(icon, size: 16, color: AppColors.gold),
                  Text(value, style: context.text.titleMedium),
                ],
              ),
            ),
            FittedBox(
              child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyActions extends StatelessWidget {
  const _MyActions({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.editProfile),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar perfil'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.wallet),
            icon: const Icon(Icons.monetization_on_outlined, size: 18),
            label: Text('${Formatters.number(user.coins)} moedas'),
          ),
        ),
      ],
    );
  }
}

class _VisitorActions extends StatelessWidget {
  const _VisitorActions({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final me = context.select((SessionCubit c) => c.state.userOrNull);
    final following = me?.followingIds.contains(user.id) ?? false;
    final subscribed = me?.subscribedCommunityIds.contains(user.id) ?? false;
    final cubit = context.read<ProfileCubit>();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: following
                  ? OutlinedButton(onPressed: cubit.toggleFollow, child: const Text('Seguindo'))
                  : FilledButton(onPressed: cubit.toggleFollow, child: const Text('Seguir')),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Mensagem',
              onPressed: () async {
                try {
                  final thread = await context.read<ChatRepository>().openWith(user);
                  if (context.mounted) context.push(AppRoutes.chat(thread.id));
                } on AppException catch (e) {
                  if (context.mounted) context.showMessage(e.message, error: true);
                }
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            IconButton.outlined(
              tooltip: 'Enviar moedas',
              onPressed: () => context.push(AppRoutes.sendCoins(user.id)),
              icon: const Icon(Icons.monetization_on_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mais opções',
              onSelected: (action) async {
                if (action == 'report') return showReportSheet(context, ReportTarget.profile, user.id);
                try {
                  final (blocked, me) = await context.read<ModerationRepository>().toggleBlock(user.id);
                  if (!context.mounted) return;
                  context.read<SessionCubit>().updateUser(me);
                  context.showMessage(
                    blocked
                        ? 'Perfil bloqueado. Vocês não verão mais as publicações um do outro.'
                        : 'Perfil desbloqueado.',
                  );
                } on AppException catch (e) {
                  if (context.mounted) context.showMessage(e.message, error: true);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'block', child: Text('Bloquear / desbloquear')),
                PopupMenuItem(value: 'report', child: Text('Denunciar perfil')),
              ],
            ),
          ],
        ),
        if (user.accountType == AccountType.community) ...[
          const SizedBox(height: 8),
          subscribed
              ? const OutlinedButton(onPressed: null, child: Text('Você é inscrito nesta comunidade'))
              : PrimaryButton(
                  label: 'Inscrever-se na comunidade',
                  color: AppColors.orange,
                  onPressed: () => context.push(AppRoutes.subscribe(user.id)),
                ),
        ],
      ],
    );
  }
}

/// Cores da capa de recompensa (pelo tema do ícone).
List<Color> _coverColors(Reward? cover) => switch (cover?.icon) {
  'forest' => const [Color(0xFF2E7D32), Color(0xFF81C784)],
  'recycle' => const [Color(0xFF00897B), Color(0xFF4DB6AC)],
  null => const [AppColors.orange, Color(0xFFFFA16C)],
  _ => const [AppColors.primary, Color(0xFF9FA8FF)],
};
