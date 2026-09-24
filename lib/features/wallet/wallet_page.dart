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
import 'wallet_cubit.dart';

/// "Carteira": saldo, compra de moedas e histórico.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  static Widget route(BuildContext context) => BlocProvider(
    create: (context) => WalletCubit(context.read<WalletRepository>(), context.read<SessionCubit>())..load(),
    child: const WalletPage(),
  );

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.userOrNull);
    return BlocConsumer<WalletCubit, WalletState>(
      listenWhen: (a, b) => a.error != b.error || a.message != b.message,
      listener: (context, state) {
        if (state.error != null) context.showMessage(state.error!, error: true);
        if (state.message != null) context.showMessage(state.message!);
      },
      builder: (context, state) {
        final cubit = context.read<WalletCubit>();
        if (user == null) return const SizedBox.shrink();
        return Scaffold(
          appBar: AppBar(title: const Text('Carteira')),
          body: RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.orange, Color(0xFFFFA16C)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo', style: TextStyle(color: Colors.white70)),
                      Text(
                        Formatters.currency(user.balance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.headlineMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          CoinChip(coins: user.coins, light: true),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.white),
                            onPressed: cubit.addFunds,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Adicionar saldo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.friendPicker),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Enviar moedas para um amigo'),
                  ),
                ),
                const SectionHeader(title: 'Comprar moedas'),
                SizedBox(
                  height: 110 + 44 * context.textScale,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: WalletRepository.packages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final package = WalletRepository.packages[i];
                      return _PackageCard(
                        package: package,
                        loading: state.buying == package,
                        onTap: () => _confirmPurchase(context, package),
                      );
                    },
                  ),
                ),
                const SectionHeader(title: 'Histórico'),
                AsyncBody(
                  status: state.status,
                  builder: (context) =>
                      Column(children: [for (final t in state.history) _TransactionTile(transaction: t)]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmPurchase(BuildContext context, CoinPackage package) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comprar moedas'),
        content: Text(
          'Comprar ${Formatters.number(package.coins)} moedas por ${Formatters.currency(package.price)}? '
          'O valor será descontado do saldo da carteira.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 40)),
            onPressed: () => context.pop(true),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
    if ((ok ?? false) && context.mounted) context.read<WalletCubit>().buy(package);
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package, required this.loading, required this.onTap});

  final CoinPackage package;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 40),
            const SizedBox(height: 6),
            FittedBox(child: Text(Formatters.number(package.coins), style: context.text.titleLarge)),
            const SizedBox(height: 4),
            loading
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    Formatters.currency(package.price),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final icon = switch (t.kind) {
      TransactionKind.purchase => Icons.monetization_on_rounded,
      TransactionKind.donation => Icons.volunteer_activism_rounded,
      TransactionKind.subscription => Icons.groups_rounded,
      TransactionKind.coinsSent => Icons.send_rounded,
      TransactionKind.reward => Icons.emoji_events_rounded,
      TransactionKind.store => Icons.storefront_rounded,
    };
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(t.kind.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text('${t.description}\n${Formatters.date(t.date)}', maxLines: 2, overflow: TextOverflow.ellipsis),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (t.money != 0)
            Text(
              Formatters.currency(t.money),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: t.money < 0 ? AppColors.textDark : AppColors.success,
              ),
            ),
          if (t.coins != 0) CoinChip(coins: t.coins, prefix: t.coins > 0 ? '+' : ''),
        ],
      ),
    );
  }
}
