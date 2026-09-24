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

/// Evento Confirmado 1/2. Só exibe dados, então usa um FutureBuilder
/// em vez de um cubit próprio.
class EventConfirmedPage extends StatelessWidget {
  const EventConfirmedPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.userOrNull);
    return Scaffold(
      body: FutureBuilder<Post>(
        future: context.read<PostRepository>().getById(postId),
        builder: (context, snapshot) {
          final post = snapshot.data;
          if (post == null || user == null) return const Center(child: CircularProgressIndicator());
          return RewardSuccessView(
            icon: Icons.celebration_rounded,
            title: 'Presença confirmada!',
            message:
                '${post.title}\n'
                '${post.startsAt == null ? '' : Formatters.dateTime(post.startsAt!)}\n'
                '${post.link ?? post.location ?? ''}',
            user: user,
            coins: post.rewardCoins,
            xp: post.rewardXp,
            actions: [
              PrimaryButton(
                label: 'Adicionar ao calendário',
                icon: Icons.event_available_rounded,
                onPressed: () => context.showMessage('Evento adicionado ao calendário (simulado).'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => context.go(AppRoutes.home), child: const Text('Voltar ao início')),
              const SizedBox(height: 8),
              Text(
                post.attending == 1
                    ? '1 pessoa confirmada'
                    : '${Formatters.compact(post.attending)} pessoas confirmadas',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}
