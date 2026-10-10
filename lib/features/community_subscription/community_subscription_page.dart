import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'community_subscription_cubit.dart';

/// Inscrição Comunidade 1 (benefícios e planos) e 2 (confirmação).
class CommunitySubscriptionPage extends StatelessWidget {
  const CommunitySubscriptionPage({super.key});

  static Widget route(BuildContext context, String communityId) => BlocProvider(
    create: (context) => CommunitySubscriptionCubit(
      communityId,
      context.read<UserRepository>(),
      context.read<WalletRepository>(),
      context.read<SessionCubit>(),
    )..load(),
    child: const CommunitySubscriptionPage(),
  );

  static const _benefits = [
    (Icons.volunteer_activism_rounded, 'Apoio direto à causa, repassado via Pix à comunidade'),
    (Icons.notifications_active_rounded, 'Novidades e atualizações das campanhas'),
    (Icons.forum_rounded, 'Grupo de mensagens da comunidade'),
    (Icons.monetization_on_rounded, '+50 moedas e +80 XP na primeira inscrição'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommunitySubscriptionCubit, CommunitySubscriptionState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => context.showMessage(state.error!, error: true),
      builder: (context, state) {
        final cubit = context.read<CommunitySubscriptionCubit>();
        if (state.done) {
          return AppPage(
            body: RewardSuccessView(
              icon: Icons.groups_rounded,
              title: 'Inscrição confirmada!',
              message: 'Agora você apoia ${state.community!.name} todo mês. Obrigado!',
              user: context.currentUser,
              coins: 50,
              xp: 80,
              actions: [PrimaryButton(label: 'Voltar para a comunidade', onPressed: () => context.pop())],
            ),
          );
        }
        return AppPage(
          appBar: AppBar(leading: const AppBackButton(), title: const Text('Inscrição')),
          body: AsyncBody(
            status: state.status,
            builder: (context) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: UserAvatar(name: state.community!.name, imageUrl: state.community!.avatarUrl, size: 88),
                ),
                const SizedBox(height: 12),
                Text(state.community!.name, textAlign: TextAlign.center, style: context.text.titleLarge),
                Text(
                  state.community!.bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                Text('Benefícios de apoiador', style: context.text.titleMedium),
                for (final (icon, text) in _benefits)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon, color: AppColors.orange),
                    title: Text(text, style: const TextStyle(fontSize: 14)),
                  ),
                const SizedBox(height: 12),
                if (state.plans?.mine case final mine? when mine.isActive) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mine.status == 'cancelled'
                          ? 'Inscrição cancelada. Você continua apoiador até ${Formatters.date(mine.currentPeriodEnd.toLocal())}.'
                          : 'Você é apoiador até ${Formatters.date(mine.currentPeriodEnd.toLocal())}. Obrigado!',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (mine.status == 'active')
                    TextButton(
                      onPressed: state.submitting ? null : cubit.cancel,
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      child: const Text('Cancelar renovação'),
                    ),
                ] else ...[
                  Text('Escolha o plano', style: context.text.titleMedium),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: state.planId,
                    onChanged: (v) => cubit.selectPlan(v!),
                    child: Column(
                      children: [
                        for (final plan in state.plans?.plans ?? const <SubscriptionPlan>[])
                          RadioListTile<String>(
                            value: plan.id,
                            title: Text(plan.name),
                            subtitle: plan.benefits.isEmpty ? null : Text(plan.benefits),
                            secondary: Text(Formatters.currency(plan.price), style: context.text.titleMedium),
                          ),
                      ],
                    ),
                  ),
                  if ((state.plans?.subscribers ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${state.plans!.subscribers} apoiador(es) ativos',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Confirmar inscrição',
                    onPressed: cubit.intent == null
                        ? null
                        : () async {
                            final user = await showCheckout(context, cubit.intent!);
                            if (user != null) await cubit.paid(user);
                          },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
