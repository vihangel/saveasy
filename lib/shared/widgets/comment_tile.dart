import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../data/models/models.dart';
import '../utils/formatters.dart';
import 'user_avatar.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment, this.onLike});

  final Comment comment;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(name: comment.authorName, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.relative(comment.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    InkWell(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            comment.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: comment.liked ? AppColors.danger : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text('${comment.likes}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Responder',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (comment.replies > 0 && comment.lastReplyAuthor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${comment.lastReplyAuthor} respondeu · Ver mais ${comment.replies} respostas',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
