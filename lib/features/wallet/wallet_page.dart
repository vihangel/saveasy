import 'package:flutter/foundation.dart';
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
          appBar: AppBar(leading: const AppBackButton(), title: const Text('Carteira')),
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
                      const Text('Suas moedas', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      CoinChip(coins: user.coins, light: true),
                      const SizedBox(height: 8),
                      const Text(
                        'Use moedas para resgatar recompensas, enviar para amigos ou doar para campanhas.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.friendPicker),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Enviar moedas'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.orders),
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('Meus pedidos'),
                      ),
                      if (user.accountType != AccountType.personal)
                        OutlinedButton.icon(
                          onPressed: () => context.push(AppRoutes.finance),
                          icon: const Icon(Icons.insights_rounded),
                          label: const Text('Painel financeiro'),
                        ),
                    ],
                  ),
                ),
                // Moedas são bem digital: nas lojas exigem a cobrança da própria loja
                // (Play Billing / App Store). Até integrar, a compra fica só na web.
                if (kIsWeb) ...[
                  const SectionHeader(title: 'Comprar moedas'),
                  SizedBox(
                    height: 110 + 44 * context.textScale,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: state.packages.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final package = state.packages[i];
                        return _PackageCard(package: package, loading: false, onTap: () => _buy(context, package));
                      },
                    ),
                  ),
                ],
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

  Future<void> _buy(BuildContext context, CoinPackage package) async {
    final user = await showCheckout(context, PaymentIntent.coins(package));
    if (user != null && context.mounted) await context.read<WalletCubit>().purchased(package, user);
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
      TransactionKind.coinsReceived => Icons.call_received_rounded,
      TransactionKind.bonus => Icons.card_giftcard_rounded,
      TransactionKind.participation => Icons.diversity_3_rounded,
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
