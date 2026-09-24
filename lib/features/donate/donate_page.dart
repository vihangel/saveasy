import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'donate_cubit.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  static Widget route(BuildContext context, String postId) => BlocProvider(
    create: (context) => DonateCubit(
      postId,
      context.read<PostRepository>(),
      context.read<WalletRepository>(),
      context.read<SessionCubit>(),
    )..load(),
    child: const DonatePage(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DonateCubit, DonateState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => context.showMessage(state.error!, error: true),
      builder: (context, state) {
        if (state.done) {
          final post = state.post!;
          return Scaffold(
            body: RewardSuccessView(
              icon: Icons.volunteer_activism_rounded,
              title: 'Obrigado pela doação!',
              message: 'Sua contribuição para "${post.title}" já está fazendo a diferença.',
              highlight: Formatters.currency(state.amount),
              user: context.currentUser,
              coins: post.rewardCoins,
              xp: post.rewardXp,
              actions: [
                PrimaryButton(label: 'Voltar para a publicação', onPressed: () => context.pop()),
                TextButton(onPressed: () => context.go(AppRoutes.home), child: const Text('Ir para o início')),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(leading: const AppBackButton(), title: const Text('Doar')),
          body: AsyncBody(
            status: state.status,
            builder: (context) => _AmountForm(state: state),
          ),
        );
      },
    );
  }
}

class _AmountForm extends StatefulWidget {
  const _AmountForm({required this.state});

  final DonateState state;

  @override
  State<_AmountForm> createState() => _AmountFormState();
}

class _AmountFormState extends State<_AmountForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(double value) {
    _controller.text = value.toStringAsFixed(0);
    context.read<DonateCubit>().setAmount(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final post = state.post!;
    final balance = context.select((SessionCubit c) => c.state.userOrNull?.balance ?? 0);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            SizedBox(
              width: 72,
              child: PostCover(type: post.type, imageUrl: post.imageUrl, height: 72, radius: 12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: context.text.titleMedium),
                  Text('Por: ${post.authorName}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (post.targetAmount != null) DonationProgress(post: post),
        const SizedBox(height: 24),
        Text('Quanto você quer doar?', style: context.text.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark),
          decoration: const InputDecoration(
            hintText: '0,00',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Text(
                r'R$',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ),
            prefixIconConstraints: BoxConstraints(),
          ),
          onChanged: (v) => context.read<DonateCubit>().setAmount(double.tryParse(v.replaceAll(',', '.')) ?? 0),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final value in DonateCubit.suggestions)
              ChoiceChip(
                label: Text(Formatters.currency(value)),
                selected: state.amount == value,
                onSelected: (_) => _select(value),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Saldo na carteira: ${Formatters.currency(balance)}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
            TextButton(onPressed: () => context.push(AppRoutes.wallet), child: const Text('Carteira')),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Doando você recebe +${post.rewardCoins} moedas e +${post.rewardXp} XP para subir de nível.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: state.amount > 0 ? 'Doar ${Formatters.currency(state.amount)}' : 'Doar',
          loading: state.submitting,
          onPressed: state.amount > 0 ? context.read<DonateCubit>().confirm : null,
        ),
      ],
    );
  }
}
