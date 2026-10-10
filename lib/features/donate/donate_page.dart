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
import '../../shared/utils/validators.dart';

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
              highlight: state.mode == DonateMode.coins
                  ? '${Formatters.number(state.coins)} moedas'
                  : Formatters.currency(state.amount),
              user: context.currentUser,
              coins: state.mode == DonateMode.coins || state.amount < 5 ? 0 : post.rewardCoins,
              xp: state.mode == DonateMode.coins ? state.coins ~/ 20 : (state.amount < 5 ? 0 : post.rewardXp),
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
    final cubit = context.read<DonateCubit>();
    final coins = context.select((SessionCubit c) => c.state.userOrNull?.coins ?? 0);
    final rate = state.fund?.coinsPerReal ?? 100;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
        SegmentedButton<DonateMode>(
          segments: const [
            ButtonSegment(value: DonateMode.money, label: Text('Pix'), icon: Icon(Icons.pix_rounded)),
            ButtonSegment(value: DonateMode.coins, label: Text('Moedas'), icon: Icon(Icons.monetization_on_rounded)),
          ],
          selected: {state.mode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => cubit.setMode(s.first),
        ),
        const SizedBox(height: 20),
        if (state.mode == DonateMode.money) ...[
          Text('Quanto você quer doar?', style: context.text.titleMedium),
          const SizedBox(height: 12),
          Semantics(
            label: 'Valor da doação em reais',
            child: TextField(
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
              onChanged: (v) => cubit.setAmount(Validators.parseMoney(v) ?? 0),
            ),
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
          const SizedBox(height: 16),
          _Info(
            text:
                'Doações a partir de R\$ 5 dão +${post.rewardCoins} moedas e +${post.rewardXp} XP '
                '(uma vez por dia por campanha).',
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: state.amount > 0 ? 'Doar ${Formatters.currency(state.amount)}' : 'Doar',
            onPressed: state.amount >= 1
                ? () async {
                    final user = await showCheckout(context, cubit.intent);
                    if (user != null) await cubit.paid(user);
                  }
                : null,
          ),
        ] else ...[
          Text('Quantas moedas?', style: context.text.titleMedium),
          const SizedBox(height: 4),
          Text('Você tem ${Formatters.number(coins)} moedas', style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in DonateCubit.coinSuggestions)
                ChoiceChip(
                  label: Text(Formatters.number(value)),
                  selected: state.coins == value,
                  onSelected: value <= coins ? (_) => cubit.setCoins(value) : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Info(
            text:
                'O fundo de doações do Save Easy converte suas moedas em dinheiro para a campanha: '
                '$rate moedas = R\$ 1,00. Saldo do fundo: ${Formatters.currency(state.fund?.balance ?? 0)}.',
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: state.coins > 0
                ? 'Doar ${Formatters.number(state.coins)} moedas (${Formatters.currency(state.coins / rate)})'
                : 'Doar moedas',
            loading: state.submitting,
            onPressed: state.coins > 0 ? cubit.donateCoins : null,
          ),
        ],
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
