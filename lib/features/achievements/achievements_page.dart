import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/widgets/widgets.dart';
import 'achievements_cubit.dart';

/// "Conquista - Principal".
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  static Widget route(BuildContext context) => BlocProvider(
    create: (context) =>
        AchievementsCubit(context.read<GamificationRepository>(), context.read<SessionCubit>())..load(),
    child: const AchievementsPage(),
  );

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.userOrNull);
    return BlocConsumer<AchievementsCubit, AchievementsState>(
      listenWhen: (a, b) => b.message != null && a.message != b.message,
      listener: (context, state) => context.showMessage(state.message!),
      builder: (context, state) {
        final daily = state.items.where((a) => a.daily).toList();
        final general = state.items.where((a) => !a.daily).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Conquistas')),
          body: AsyncBody(
            status: state.status,
            builder: (context) => ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                if (user != null) LevelCard(user: user),
                const SectionHeader(title: 'Faça objetivos diários'),
                for (final a in daily) _AchievementTile(achievement: a),
                const SectionHeader(title: 'Conquistas populares'),
                for (final a in general.where((a) => !a.completed)) _AchievementTile(achievement: a),
                const SectionHeader(title: 'Concluídas'),
                for (final a in general.where((a) => a.completed)) _AchievementTile(achievement: a),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final color = a.completed ? AppColors.success : AppColors.orange;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(a.completed ? Icons.emoji_events_rounded : Icons.flag_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                ProgressBar(value: a.progress, color: color),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${a.current.clamp(0, a.goal)}/${a.goal} · ${(a.progress * 100).round()}%',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    if (!a.claimed) CoinChip(coins: a.rewardCoins, prefix: '+'),
                  ],
                ),
                if (a.completed && !a.claimed) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 36), backgroundColor: AppColors.success),
                    onPressed: () => context.read<AchievementsCubit>().claim(a.id),
                    child: const Text('Resgatar'),
                  ),
                ],
              ],
            ),
          ),
          if (a.claimed) ...[
            const SizedBox(width: 12),
            const Icon(Icons.check_circle_rounded, color: AppColors.success),
          ],
        ],
      ),
    );
  }
}
