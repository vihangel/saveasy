import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'post_detail_cubit.dart';

/// Detalhe de qualquer publicação (Doação 1-5, Evento 1-4, Ação Social 1-5,
/// Atividade 1-4, Tutorial 1-2, Discussão 2-3). As seções específicas
/// mudam de acordo com o tipo.
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  static Widget route(BuildContext context, String postId) => BlocProvider(
    create: (context) => PostDetailCubit(
      postId: postId,
      posts: context.read<PostRepository>(),
      users: context.read<UserRepository>(),
      session: context.read<SessionCubit>(),
    )..load(),
    child: PostDetailPage(postId: postId),
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostDetailCubit, PostDetailState>(
      listenWhen: (a, b) => b.message != null && a.message != b.message,
      listener: (context, state) {
        context.showMessage(state.message!);
        context.read<PostDetailCubit>().messageShown();
      },
      builder: (context, state) {
        return Scaffold(
          body: AsyncBody(
            status: state.status,
            error: state.error,
            onRetry: context.read<PostDetailCubit>().load,
            builder: (context) => _Content(state: state),
          ),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final PostDetailState state;

  @override
  Widget build(BuildContext context) {
    final post = state.post!;
    final cubit = context.read<PostDetailCubit>();
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                leading: const AppBackButton(color: Colors.white),
                expandedHeight: 240,
                backgroundColor: PostCover.colorsFor(post.type).last,
                foregroundColor: Colors.white,
                title: Text(post.type.label, style: const TextStyle(color: Colors.white)),
                actions: [
                  IconButton(
                    icon: Icon(post.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                    onPressed: cubit.toggleSave,
                  ),
                  IconButton(icon: const Icon(Icons.share_outlined), onPressed: cubit.share),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: PostCover(type: post.type, imageUrl: post.imageUrl, height: 280, radius: 0, iconSize: 72),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                sliver: SliverList.list(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in post.categories)
                          Chip(label: Text(c.label), visualDensity: VisualDensity.compact),
                        _StatusChip(post: post),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(post.title, style: context.text.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Por: ${post.authorName}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 16),
                    Text(post.description, style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 20),
                    ..._typeSection(context, post),
                    const SizedBox(height: 20),
                    if (state.author != null) _AuthorCard(author: state.author!),
                    const SizedBox(height: 16),
                    _RewardInfo(post: post),
                    const SizedBox(height: 8),
                    ReactionBar(
                      likes: post.likes,
                      liked: post.liked,
                      comments: state.comments.length,
                      shares: post.shares,
                      onLike: cubit.toggleLike,
                      onShare: cubit.share,
                    ),
                    const Divider(height: 24),
                    Text('Comentários (${state.comments.length})', style: context.text.titleMedium),
                    if (state.comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Seja o primeiro a comentar!', style: TextStyle(color: AppColors.textMuted)),
                      ),
                    for (final comment in state.comments)
                      CommentTile(comment: comment, onLike: () => cubit.toggleCommentLike(comment.id)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _CommentInput(sending: state.sendingComment, onSend: cubit.addComment),
      ],
    );
  }

  List<Widget> _typeSection(BuildContext context, Post post) {
    final cubit = context.read<PostDetailCubit>();

    Future<void> participate() async {
      final confirmed = await cubit.toggleParticipation();
      if (confirmed && post.type == PostType.event && context.mounted) {
        context.push(AppRoutes.eventConfirmed(post.id));
      }
    }

    switch (post.type) {
      case PostType.donation:
        return [
          _InfoBox(
            children: [
              if (post.targetAmount != null) ...[
                DonationProgress(post: post),
                const SizedBox(height: 8),
                Text(
                  'Faltam ${Formatters.currency(post.remainingAmount)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
              if (post.subtype.isNotEmpty) _InfoRow(icon: Icons.label_outline_rounded, text: post.subtype),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Doar',
            icon: Icons.volunteer_activism_rounded,
            onPressed: () async {
              await context.push(AppRoutes.donate(post.id));
              cubit.refreshPost();
            },
          ),
          const SizedBox(height: 8),
          _SendCoinsButton(post: post),
        ];
      case PostType.event:
        return [
          _InfoBox(
            children: [
              _InfoRow(
                icon: post.link != null ? Icons.live_tv_rounded : Icons.place_rounded,
                text: post.link ?? post.location ?? 'Local a definir',
              ),
              if (post.startsAt != null) _InfoRow(icon: Icons.event_rounded, text: Formatters.dateTime(post.startsAt!)),
              _InfoRow(
                icon: Icons.groups_rounded,
                text:
                    '${Formatters.compact(post.attending)}'
                    '${post.capacity == null ? '' : '/${Formatters.compact(post.capacity!)}'} participantes',
              ),
              if (post.capacity != null) ProgressBar(value: post.attending / post.capacity!, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 16),
          _ParticipateButton(
            post: post,
            loading: state.participating,
            label: 'Confirmar presença',
            confirmedLabel: 'Presença confirmada · Cancelar',
            onPressed: participate,
          ),
          const SizedBox(height: 8),
          _SendCoinsButton(post: post),
        ];
      case PostType.socialAction:
      case PostType.activity:
        return [
          _InfoBox(
            children: [
              if (post.location != null) _InfoRow(icon: Icons.place_rounded, text: post.location!),
              if (post.startsAt != null) _InfoRow(icon: Icons.event_rounded, text: Formatters.dateTime(post.startsAt!)),
              _InfoRow(icon: Icons.groups_rounded, text: '${post.attending} participantes'),
            ],
          ),
          const SizedBox(height: 16),
          _ParticipateButton(
            post: post,
            loading: state.participating,
            label: 'Quero participar',
            confirmedLabel: 'Você está participando · Sair',
            onPressed: participate,
          ),
          const SizedBox(height: 8),
          _SendCoinsButton(post: post),
        ];
      case PostType.tutorial:
        return [
          if (post.durationMinutes != null)
            _InfoRow(icon: Icons.timer_outlined, text: 'Duração: ${Formatters.duration(post.durationMinutes!)}'),
          const SizedBox(height: 8),
          Text('Passo a passo', style: context.text.titleMedium),
          const SizedBox(height: 8),
          for (final (i, step) in post.steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(step)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _SendCoinsButton(post: post),
        ];
      case PostType.discussion:
        return [
          _InfoBox(
            children: const [
              _InfoRow(
                icon: Icons.forum_outlined,
                text: 'Participe da discussão deixando sua opinião nos comentários.',
              ),
            ],
          ),
        ];
      case PostType.ad:
        return [
          _InfoBox(
            children: [
              const _InfoRow(icon: Icons.campaign_outlined, text: 'Publicação patrocinada'),
              if (post.adPlan != null) _InfoRow(icon: Icons.calendar_month_outlined, text: 'Plano ${post.adPlan}'),
            ],
          ),
        ];
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final text = switch (post.type) {
      PostType.donation when post.recurring => 'Recorrente',
      PostType.donation when post.endsAt != null => Formatters.daysLeft(post.endsAt!),
      PostType.event when post.startsAt != null =>
        post.isFinished ? 'Finalizado' : Formatters.countdown(post.startsAt!),
      _ => post.subtype,
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: post.isFinished ? AppColors.textMuted : AppColors.orange,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, child) in children.indexed) ...[if (i > 0) const SizedBox(height: 10), child],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
        ),
      ],
    );
  }
}

class _ParticipateButton extends StatelessWidget {
  const _ParticipateButton({
    required this.post,
    required this.loading,
    required this.label,
    required this.confirmedLabel,
    required this.onPressed,
  });

  final Post post;
  final bool loading;
  final String label;
  final String confirmedLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (post.isFinished) {
      return const FilledButton(onPressed: null, child: Text('Finalizado'));
    }
    if (post.confirmed) {
      return OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: const Icon(Icons.check_circle_rounded),
        label: Text(confirmedLabel),
      );
    }
    return PrimaryButton(label: label, loading: loading, onPressed: onPressed);
  }
}

class _SendCoinsButton extends StatelessWidget {
  const _SendCoinsButton({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    if (post.authorId == context.currentUser.id) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: () => context.push(AppRoutes.sendCoins(post.authorId, postId: post.id)),
      icon: const Icon(Icons.monetization_on_outlined),
      label: const Text('Enviar moedas para o autor'),
    );
  }
}

/// Card "Endorsed-by" do Figma: quem publicou/apoia, com botão seguir.
class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.author});

  final AppUser author;

  @override
  Widget build(BuildContext context) {
    final me = context.select((SessionCubit c) => c.state.userOrNull);
    final isMe = me?.id == author.id;
    final following = me?.followingIds.contains(author.id) ?? false;
    return InkWell(
      onTap: () => context.push(AppRoutes.user(author.id)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            UserAvatar(name: author.name, imageUrl: author.avatarUrl, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  Text(
                    '${author.accountType.label} · ${Formatters.compact(author.followers)} seguidores',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (!isMe)
              SizedBox(
                height: 36,
                child: following
                    ? OutlinedButton(
                        onPressed: context.read<PostDetailCubit>().toggleFollowAuthor,
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                        child: const Text('Seguindo'),
                      )
                    : FilledButton(
                        onPressed: context.read<PostDetailCubit>().toggleFollowAuthor,
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                        child: const Text('Seguir'),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RewardInfo extends StatelessWidget {
  const _RewardInfo({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final action = switch (post.type) {
      PostType.donation => 'Ao doar',
      PostType.event => 'Ao participar deste evento',
      PostType.ad => 'Ao assistir o anúncio',
      _ => 'Ao participar',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('$action você ganha:', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                CoinChip(coins: post.rewardCoins, prefix: '+'),
                Text(
                  '+${post.rewardXp} XP',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatefulWidget {
  const _CommentInput({required this.sending, required this.onSend});

  final bool sending;
  final ValueChanged<String> onSend;

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    widget.onSend(_controller.text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              UserAvatar(name: context.currentUser.name, imageUrl: context.currentUser.avatarUrl, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Escreva um comentário...'),
                ),
              ),
              IconButton(
                onPressed: widget.sending ? null : _send,
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
