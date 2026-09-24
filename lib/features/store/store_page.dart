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
import 'store_cubit.dart';

class StoreListener extends StatelessWidget {
  const StoreListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<StoreCubit, StoreState>(
      listenWhen: (a, b) => a.error != b.error || a.message != b.message,
      listener: (context, state) {
        if (state.error != null) context.showMessage(state.error!, error: true);
        if (state.message != null) context.showMessage(state.message!);
      },
      child: child,
    );
  }
}

/// "Loja - Principal".
class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final balance = context.select((SessionCubit c) => c.state.userOrNull?.balance ?? 0);
    return StoreListener(
      child: Scaffold(
        appBar: AppBar(title: const Text('Lojas da Comunidade')),
        body: BlocBuilder<StoreCubit, StoreState>(
          builder: (context, state) {
            final cubit = context.read<StoreCubit>();
            return ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Saldo', style: TextStyle(color: AppColors.textMuted)),
                      ),
                      Text(Formatters.currency(balance), style: context.text.titleMedium),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: TextField(
                    onChanged: cubit.search,
                    decoration: const InputDecoration(hintText: 'Pesquisar', prefixIcon: Icon(Icons.search_rounded)),
                  ),
                ),
                if (state.status.isSuccess && state.products.isEmpty)
                  const EmptyState(message: 'Nenhum produto encontrado.'),
                if (!state.status.isSuccess)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                for (final section in StoreSection.values)
                  if (state.products.any((p) => p.section == section)) ...[
                    SectionHeader(title: section.label),
                    SizedBox(
                      height: 210,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          for (final p in state.products.where((p) => p.section == section))
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _ProductCard(product: p),
                            ),
                        ],
                      ),
                    ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.product(product.id)),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(product: product, height: 130),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            Text(
              product.communityName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            Text(
              Formatters.currency(product.price),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.height});

  final Product product;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Icon(AppIcons.byKey(product.icon), size: height * 0.45, color: AppColors.primary),
      ),
    );
  }
}

/// Loja 3 / Loja 5: detalhe do produto.
class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return StoreListener(
      child: BlocBuilder<StoreCubit, StoreState>(
        builder: (context, state) {
          final product = state.products.where((p) => p.id == productId).firstOrNull;
          return Scaffold(
            appBar: AppBar(),
            body: product == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _ProductImage(product: product, height: 240),
                      const SizedBox(height: 24),
                      Text(product.name, style: context.text.headlineSmall),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => context.push(AppRoutes.user(product.communityId)),
                        child: Row(
                          children: [
                            UserAvatar(name: product.communityName, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                product.communityName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                            const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                            Text(product.rating.toStringAsFixed(1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(product.description, style: const TextStyle(height: 1.5)),
                      const SizedBox(height: 24),
                      Text(
                        Formatters.currency(product.price),
                        style: context.text.headlineMedium?.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Comprando você ganha +20 moedas e +30 XP',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Comprar',
                        icon: Icons.shopping_bag_outlined,
                        loading: state.buyingId == product.id,
                        onPressed: () => context.read<StoreCubit>().buy(product),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
