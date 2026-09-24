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
            _ActionResume(state: state),
            _Album(posts: state.posts, name: user.name),
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.orange, Color(0xFFFFA16C)]),
                ),
              ),
              SafeArea(
                child: Row(
                  children: [
                    if (showBack) const AppBackButton(color: Colors.white),
                    const Spacer(),
                    if (state.isMe)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                        onPressed: () => context.push(AppRoutes.editProfile),
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
              _Stat(value: Formatters.compact(user.followers), label: 'Seguidores'),
              _Stat(value: Formatters.compact(user.following), label: 'Seguindo'),
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
  const _Stat({required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
            label: Text(Formatters.currency(user.balance)),
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
                final thread = await context.read<ChatRepository>().openWith(user);
                if (context.mounted) context.push(AppRoutes.chat(thread.id));
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            IconButton.outlined(
              tooltip: 'Enviar moedas',
              onPressed: () => context.push(AppRoutes.sendCoins(user.id)),
              icon: const Icon(Icons.monetization_on_outlined),
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

/// "Currículo de Ações": resumo das boas ações do usuário.
class _ActionResume extends StatelessWidget {
  const _ActionResume({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    final user = state.user!;
    final donations = state.history.where((t) => t.kind == TransactionKind.donation).toList();
    final donated = donations.fold<double>(0, (sum, t) => sum - t.money);
    final byType = <PostType, int>{};
    for (final p in state.posts) {
      byType[p.type] = (byType[p.type] ?? 0) + 1;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Row(
          children: [
            _ResumeCard(icon: Icons.bolt_rounded, value: '${user.xp}', label: 'XP total'),
            const SizedBox(width: 12),
            _ResumeCard(
              icon: Icons.volunteer_activism_rounded,
              value: state.isMe ? Formatters.currency(donated) : '${state.posts.length}',
              label: state.isMe ? 'Doado' : 'Ações publicadas',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Ações por tipo', style: context.text.titleMedium),
        const SizedBox(height: 8),
        if (byType.isEmpty) const Text('Nenhuma ação publicada ainda.', style: TextStyle(color: AppColors.textMuted)),
        for (final MapEntry(key: type, value: count) in byType.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: PostCover.colorsFor(type).last.withValues(alpha: 0.12),
              child: Icon(AppIcons.postType(type), color: PostCover.colorsFor(type).last),
            ),
            title: Text(type.label),
            trailing: Text('$count', style: context.text.titleMedium),
          ),
        if (state.isMe && donations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Doações recentes', style: context.text.titleMedium),
          for (final t in donations)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.description, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(Formatters.date(t.date)),
              trailing: Text(
                Formatters.currency(-t.money),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
              ),
            ),
        ],
      ],
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.orange),
            const SizedBox(height: 8),
            Text(value, style: context.text.titleLarge),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// "Álbum de boas ações": grade com as capas das publicações.
class _Album extends StatelessWidget {
  const _Album({required this.posts, required this.name});

  final List<Post> posts;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const EmptyState(message: 'O álbum ainda está vazio.', icon: Icons.photo_library_outlined);
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: posts.length,
      itemBuilder: (context, i) => InkWell(
        onTap: () => context.push(AppRoutes.post(posts[i].id)),
        child: PostCover(
          type: posts[i].type,
          imageUrl: posts[i].imageUrl,
          height: double.infinity,
          radius: 4,
          iconSize: 32,
        ),
      ),
    );
  }
}
