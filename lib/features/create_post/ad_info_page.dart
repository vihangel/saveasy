import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/widgets/widgets.dart';

/// "Propaganda - Info": explica como funciona antes de criar.
class AdInfoPage extends StatelessWidget {
  const AdInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.visibility_rounded, 'Mais alcance', 'Sua publicação aparece em destaque no feed e nos stories.'),
      (
        Icons.monetization_on_rounded,
        'Quem assiste ganha',
        'Usuários ganham moedas ao ver sua propaganda, aumentando o engajamento.',
      ),
      (Icons.volunteer_activism_rounded, 'Para boas causas', 'Divulgue uma campanha ou o seu currículo de boas ações.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Propaganda')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PostCover(type: PostType.ad, height: 180),
          const SizedBox(height: 24),
          Text('Divulgue suas boas ações', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Com a propaganda você impulsiona uma publicação para que mais pessoas conheçam e apoiem a sua causa.',
            style: TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 24),
          for (final (icon, title, body) in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(icon, color: AppColors.primary),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(body),
            ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Criar propaganda',
            onPressed: () => context.push(AppRoutes.createForm(PostType.ad.name)),
          ),
        ],
      ),
    );
  }
}
