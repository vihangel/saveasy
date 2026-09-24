import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../data/models/models.dart';
import '../utils/app_icons.dart';
import '../utils/formatters.dart';
import 'post_cover.dart';
import 'progress_bar.dart';
import 'reaction_bar.dart';
import 'user_avatar.dart';

class PostTypeChip extends StatelessWidget {
  const PostTypeChip({super.key, required this.type, this.light = false});

  final PostType type;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = PostCover.colorsFor(type).last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: light ? Colors.white : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.postType(type), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// Informação principal de cada tipo (prazo, data do evento, duração...).
class PostMetaLine extends StatelessWidget {
  const PostMetaLine({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String text)? meta = switch (post.type) {
      PostType.donation when post.recurring => (Icons.autorenew_rounded, 'Recorrente'),
      PostType.donation when post.endsAt != null => (Icons.schedule_rounded, Formatters.daysLeft(post.endsAt!)),
      PostType.event when post.startsAt != null => (Icons.event_rounded, Formatters.dateTime(post.startsAt!)),
      PostType.socialAction || PostType.activity when post.location != null => (Icons.place_rounded, post.location!),
      PostType.tutorial when post.durationMinutes != null => (
        Icons.timer_outlined,
        Formatters.duration(post.durationMinutes!),
      ),
      _ => null,
    };
    if (meta == null) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(meta.$1, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            meta.$2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class DonationProgress extends StatelessWidget {
  const DonationProgress({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressBar(value: post.progress),
        const SizedBox(height: 6),
        Row(
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: Formatters.currency(post.raisedAmount),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 13),
                  children: [
                    TextSpan(
                      text: ' (${(post.progress * 100).round()}%)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Meta: ${Formatters.currency(post.targetAmount ?? 0)}',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Card de publicação usado no feed e nos perfis.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.commentsCount = 3, this.onLike, this.onShare});

  final Post post;
  final int commentsCount;
  final VoidCallback? onLike;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.post(post.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => context.push(AppRoutes.user(post.authorId)),
                child: Row(
                  children: [
                    UserAvatar(name: post.authorName, imageUrl: post.authorAvatarUrl, size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            Formatters.relative(post.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    PostTypeChip(type: post.type),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              PostCover(type: post.type, imageUrl: post.imageUrl, height: 150),
              const SizedBox(height: 10),
              Text(post.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                post.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              PostMetaLine(post: post),
              if (post.type == PostType.donation && post.targetAmount != null) ...[
                const SizedBox(height: 10),
                DonationProgress(post: post),
              ],
              if (post.type == PostType.event && post.capacity != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${Formatters.compact(post.attending)}/${Formatters.compact(post.capacity!)} participantes',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 4),
              ReactionBar(
                likes: post.likes,
                liked: post.liked,
                comments: commentsCount,
                shares: post.shares,
                onLike: onLike,
                onShare: onShare,
                onComment: () => context.push(AppRoutes.post(post.id)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Versão compacta horizontal ("Recomendados", "Na sua região").
class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.post, this.width = 240});

  final Post post;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => context.push(AppRoutes.post(post.id)),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PostCover(type: post.type, imageUrl: post.imageUrl, height: 120),
                Positioned(left: 8, top: 8, child: PostTypeChip(type: post.type, light: true)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(post.authorName, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            if (post.type == PostType.donation && post.targetAmount != null)
              DonationProgress(post: post)
            else
              PostMetaLine(post: post),
          ],
        ),
      ),
    );
  }
}
