import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/app_icons.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'rewards_cubit.dart';

/// Escuta mensagens do cubit de recompensas (lista e detalhe).
class RewardsListener extends StatelessWidget {
  const RewardsListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<RewardsCubit, RewardsState>(
      listenWhen: (a, b) => a.error != b.error || a.message != b.message,
      listener: (context, state) {
        if (state.error != null) context.showMessage(state.error!, error: true);
        if (state.message != null) context.showMessage(state.message!);
      },
      child: child,
    );
  }
}

/// "Recompensas - Principal".
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.userOrNull);
    return RewardsListener(
      child: Scaffold(
        appBar: AppBar(title: const Text('Recompensas')),
        body: BlocBuilder<RewardsCubit, RewardsState>(
          builder: (context, state) => AsyncBody(
            status: state.status,
            builder: (context) => ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                if (user != null) LevelCard(user: user),
                const SizedBox(height: 16),
                const _InviteBanner(),
                for (final kind in RewardKind.values) ...[
                  SectionHeader(title: '${kind.label} populares'),
                  SizedBox(
                    height: (kind == RewardKind.cover ? 150 : 120) + 40 * context.textScale,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: context.read<RewardsCubit>().byKind(kind).length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _RewardCard(reward: context.read<RewardsCubit>().byKind(kind)[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteBanner extends StatelessWidget {
  const _InviteBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_add_alt_1_rounded, color: AppColors.orange, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Convide e ganhe pontos',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                Text('Ganhe 250 moedas por amigo que criar uma conta.', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          TextButton(onPressed: () => context.showMessage('Link de convite copiado!'), child: const Text('Convidar')),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward});

  final Reward reward;

  @override
  Widget build(BuildContext context) {
    final isCover = reward.kind == RewardKind.cover;
    return InkWell(
      onTap: () => context.push(AppRoutes.reward(reward.id)),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: isCover ? 160 : 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RewardPreview(reward: reward, height: isCover ? 110 : 80),
            const SizedBox(height: 6),
            Text(
              reward.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 2),
            reward.owned
                ? const Text('Adquirido', style: TextStyle(fontSize: 12, color: AppColors.success))
                : CoinChip(coins: reward.price),
          ],
        ),
      ),
    );
  }
}

class RewardPreview extends StatelessWidget {
  const RewardPreview({super.key, required this.reward, required this.height});

  final Reward reward;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = switch (reward.kind) {
      RewardKind.cover => const [Color(0xFF8A9BFF), AppColors.primary],
      RewardKind.badge => const [Color(0xFFFFD27A), Color(0xFFF2A516)],
      RewardKind.title => const [Color(0xFFFFA16C), AppColors.orange],
    };
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(reward.kind == RewardKind.badge ? height : 16),
      ),
      child: Center(
        child: Icon(AppIcons.byKey(reward.icon), color: Colors.white, size: height * 0.45),
      ),
    );
  }
}

/// "Recompensa 1 / 3": detalhe e resgate.
class RewardDetailPage extends StatelessWidget {
  const RewardDetailPage({super.key, required this.rewardId});

  final String rewardId;

  @override
  Widget build(BuildContext context) {
    final coins = context.select((SessionCubit c) => c.state.userOrNull?.coins ?? 0);
    return RewardsListener(
      child: BlocBuilder<RewardsCubit, RewardsState>(
        builder: (context, state) {
          final reward = state.rewards.where((r) => r.id == rewardId).firstOrNull;
          return Scaffold(
            appBar: AppBar(title: Text(reward?.kind.label ?? '')),
            body: reward == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      RewardPreview(reward: reward, height: 200),
                      const SizedBox(height: 24),
                      Text(reward.name, style: context.text.headlineSmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          UserAvatar(name: reward.sponsor, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Oferecido por ${reward.sponsor}',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(reward.description, style: const TextStyle(height: 1.5)),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Preço: '),
                              CoinChip(coins: reward.price),
                            ],
                          ),
                          Text(
                            'Você tem ${Formatters.number(coins)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      reward.owned
                          ? const OutlinedButton(onPressed: null, child: Text('Você já possui este item'))
                          : PrimaryButton(
                              label: 'Resgatar',
                              loading: state.redeemingId == reward.id,
                              onPressed: () => context.read<RewardsCubit>().redeem(reward.id),
                            ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
