import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
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
    (Icons.workspace_premium_rounded, 'Selo exclusivo de apoiador no seu perfil'),
    (Icons.image_rounded, 'Capas e títulos liberados pela comunidade'),
    (Icons.forum_rounded, 'Acesso ao chat de apoiadores'),
    (Icons.monetization_on_rounded, '+50 moedas por mês'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommunitySubscriptionCubit, CommunitySubscriptionState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => context.showMessage(state.error!, error: true),
      builder: (context, state) {
        final cubit = context.read<CommunitySubscriptionCubit>();
        if (state.done) {
          return Scaffold(
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
        return Scaffold(
          appBar: AppBar(title: const Text('Inscrição')),
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
                Text('Escolha o plano', style: context.text.titleMedium),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: state.plan,
                  onChanged: (v) => cubit.selectPlan(v!),
                  child: Column(
                    children: [
                      for (final MapEntry(key: plan, value: price) in CommunitySubscriptionCubit.plans.entries)
                        RadioListTile<String>(
                          value: plan,
                          title: Text(plan),
                          secondary: Text(Formatters.currency(price), style: context.text.titleMedium),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Confirmar inscrição', loading: state.submitting, onPressed: cubit.subscribe),
              ],
            ),
          ),
        );
      },
    );
  }
}
