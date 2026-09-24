import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/view_status.dart';
import '../../shared/widgets/widgets.dart';
import '../home/home_shell.dart';
import 'feed_cubit.dart';

/// Feed 1 (Popular), Feed 2 (Na sua região) e Feed 3 (Seguindo).
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.userOrNull);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => HomeShell.scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 28),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'SavEasy',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => context.push(AppRoutes.wallet),
                child: CoinChip(coins: user.coins),
              ),
            ),
        ],
      ),
      body: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          final cubit = context.read<FeedCubit>();
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _StoriesRow(stories: state.stories)),
                SliverToBoxAdapter(
                  child: _FeedTabs(selected: state.tab, onSelected: cubit.selectTab),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: TextField(
                      onChanged: cubit.search,
                      decoration: const InputDecoration(
                        hintText: 'Pesquisar',
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      children: [
                        for (final category in PostCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category.label),
                              selected: state.category == category,
                              showCheckmark: false,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: state.category == category ? Colors.white : AppColors.text,
                                fontSize: 12,
                              ),
                              onSelected: (_) => cubit.selectCategory(category),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                ..._content(context, state),
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _content(BuildContext context, FeedState state) {
    if (state.status != ViewStatus.success) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AsyncBody(status: state.status, error: state.error, builder: (_) => const SizedBox()),
        ),
      ];
    }
    if (state.posts.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: EmptyState(message: 'Nenhuma publicação encontrada.', icon: Icons.search_off_rounded),
        ),
      ];
    }
    final cubit = context.read<FeedCubit>();
    final (highlightTitle, highlight, secondTitle, second) = switch (state.tab) {
      FeedTab.popular => ('Recomendados', state.posts.take(4).toList(), null, <Post>[]),
      FeedTab.nearby => (
        'Na sua região',
        state.posts.where((p) => p.location != null).toList(),
        'Tutoriais feitos por comunidades',
        state.posts.where((p) => p.type == PostType.tutorial).toList(),
      ),
      FeedTab.following => (
        'Visualizado por amigos',
        state.posts.take(3).toList(),
        'Novas discussões',
        state.posts.where((p) => p.type == PostType.discussion).toList(),
      ),
    };
    return [
      if (highlight.isNotEmpty) ...[
        SliverToBoxAdapter(child: SectionHeader(title: highlightTitle)),
        SliverToBoxAdapter(child: _HorizontalPosts(posts: highlight)),
      ],
      if (secondTitle != null && second.isNotEmpty) ...[
        SliverToBoxAdapter(child: SectionHeader(title: secondTitle)),
        SliverToBoxAdapter(child: _HorizontalPosts(posts: second)),
      ],
      const SliverToBoxAdapter(child: SectionHeader(title: 'Publicações')),
      SliverList.builder(
        itemCount: state.posts.length,
        itemBuilder: (context, i) {
          final post = state.posts[i];
          return PostCard(
            post: post,
            commentsCount: state.commentCounts[post.id] ?? 0,
            onLike: () => cubit.toggleLike(post.id),
            onShare: () {
              cubit.share(post.id);
              context.showMessage('Link da publicação copiado!');
            },
          );
        },
      ),
    ];
  }
}

class _FeedTabs extends StatelessWidget {
  const _FeedTabs({required this.selected, required this.onSelected});

  final FeedTab selected;
  final ValueChanged<FeedTab> onSelected;

  static const _labels = {FeedTab.popular: 'Popular', FeedTab.nearby: 'Região', FeedTab.following: 'Seguindo'};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SegmentedButton<FeedTab>(
        segments: [for (final tab in FeedTab.values) ButtonSegment(value: tab, label: Text(_labels[tab]!))],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onSelected(s.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.primary,
          selectedForegroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow({required this.stories});

  final List<Story> stories;

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    return SizedBox(
      height: 86 + 24 * context.textScale,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _StoryBubble(
            label: 'Seu story',
            onTap: () => context.push(AppRoutes.newStory),
            child: Stack(
              children: [
                UserAvatar(name: user.name, imageUrl: user.avatarUrl, size: 56),
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.orange,
                    child: Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          for (final (i, story) in stories.indexed)
            _StoryBubble(
              label: story.authorName.split(' ').first,
              onTap: () async {
                await context.push(AppRoutes.stories(i));
                if (context.mounted) context.read<FeedCubit>().load();
              },
              child: Opacity(
                opacity: story.seen ? 0.6 : 1,
                child: UserAvatar(name: story.authorName, imageUrl: story.authorAvatarUrl, size: 52, ring: !story.seen),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.label, required this.child, required this.onTap});

  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              child,
              const SizedBox(height: 4),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalPosts extends StatelessWidget {
  const _HorizontalPosts({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170 + 100 * context.textScale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: posts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => PostTile(post: posts[i]),
      ),
    );
  }
}

/// Cria o cubit do feed com as dependências do contexto.
FeedCubit createFeedCubit(BuildContext context) =>
    FeedCubit(context.read<PostRepository>(), context.read<StoryRepository>(), context.currentUser.id)..load();
