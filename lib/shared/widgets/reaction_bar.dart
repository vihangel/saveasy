import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/formatters.dart';

/// Curtidas · comentários · compartilhamentos.
class ReactionBar extends StatelessWidget {
  const ReactionBar({
    super.key,
    required this.likes,
    required this.liked,
    required this.comments,
    required this.shares,
    this.onLike,
    this.onComment,
    this.onShare,
    this.saved,
    this.onSave,
  });

  final int likes;
  final bool liked;
  final int comments;
  final int shares;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final bool? saved;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            children: [
              _Item(
                icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? AppColors.danger : AppColors.textMuted,
                label: Formatters.compact(likes),
                semanticLabel: '${liked ? 'Descurtir' : 'Curtir'}, ${Formatters.plural(likes, 'curtida', 'curtidas')}',
                onTap: onLike,
              ),
              _Item(
                icon: Icons.chat_bubble_outline_rounded,
                label: Formatters.compact(comments),
                semanticLabel: 'Comentar, ${Formatters.plural(comments, 'comentário', 'comentários')}',
                onTap: onComment,
              ),
              _Item(
                icon: Icons.share_outlined,
                label: Formatters.compact(shares),
                semanticLabel: 'Compartilhar, ${Formatters.plural(shares, 'compartilhamento', 'compartilhamentos')}',
                onTap: onShare,
              ),
            ],
          ),
        ),
        if (saved != null)
          IconButton(
            tooltip: saved! ? 'Remover dos salvos' : 'Salvar',
            onPressed: onSave,
            icon: Icon(saved! ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            color: saved! ? AppColors.primary : AppColors.textMuted,
          ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.onTap,
    this.color = AppColors.textMuted,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          // min: dentro do Wrap, cada item ocupa só o próprio tamanho.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
