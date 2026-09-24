import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'send_coins_cubit.dart';

class SendCoinsPage extends StatelessWidget {
  const SendCoinsPage({super.key});

  static Widget route(BuildContext context, String targetId, String? postId) => BlocProvider(
    create: (context) => SendCoinsCubit(
      targetId: targetId,
      postId: postId,
      users: context.read<UserRepository>(),
      posts: context.read<PostRepository>(),
      wallet: context.read<WalletRepository>(),
      session: context.read<SessionCubit>(),
    )..load(),
    child: const SendCoinsPage(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SendCoinsCubit, SendCoinsState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => context.showMessage(state.error!, error: true),
      builder: (context, state) {
        if (state.done) {
          return Scaffold(
            body: RewardSuccessView(
              icon: Icons.monetization_on_rounded,
              title: 'Moedas enviadas!',
              message:
                  '${state.target!.name} recebeu suas moedas'
                  '${state.message.isEmpty ? '.' : ' com a mensagem "${state.message}".'}',
              highlight: '${Formatters.number(state.coins)} moedas',
              user: context.currentUser,
              xp: state.coins ~/ 2,
              actions: [PrimaryButton(label: 'Concluir', onPressed: () => context.pop())],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Enviar moedas')),
          body: AsyncBody(
            status: state.status,
            builder: (context) => _Form(state: state),
          ),
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state});

  final SendCoinsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SendCoinsCubit>();
    final myCoins = context.select((SessionCubit c) => c.state.userOrNull?.coins ?? 0);
    final target = state.target!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: UserAvatar(name: target.name, imageUrl: target.avatarUrl, size: 88),
        ),
        const SizedBox(height: 12),
        Text(target.name, textAlign: TextAlign.center, style: context.text.titleLarge),
        if (state.post != null)
          Text(
            'Apoiando: ${state.post!.title}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        const SizedBox(height: 28),
        Text('Quantas moedas?', style: context.text.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in SendCoinsCubit.options)
              ChoiceChip(
                avatar: const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 18),
                label: Text('+$value'),
                selected: state.coins == value,
                onSelected: (_) => cubit.selectCoins(value),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Você tem ${Formatters.number(myCoins)} moedas',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: 'Mensagem (opcional)',
          hint: 'Escreva algo para ${target.name.split(' ').first}...',
          maxLines: 3,
          onChanged: cubit.setMessage,
        ),
        const SizedBox(height: 32),
        PrimaryButton(label: 'Enviar ${state.coins} moedas', loading: state.submitting, onPressed: cubit.send),
      ],
    );
  }
}
