import '../../app/breakpoints.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/app_icons.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/utils/view_status.dart';
import '../../shared/widgets/widgets.dart';
import 'store_cubit.dart';

/// "Loja - Principal".
class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final seller =
        context.currentUser.accountType == AccountType.community ||
        context.currentUser.accountType == AccountType.business;
    return AppPage(
      maxWidth: context.isExpanded ? 960 : Breakpoints.content,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Lojas da Comunidade'),
        actions: [
          IconButton(
            tooltip: 'Meus pedidos',
            onPressed: () => context.push(AppRoutes.orders),
            icon: const Icon(Icons.receipt_long_rounded),
          ),
          if (seller)
            IconButton(
              tooltip: 'Minha loja',
              onPressed: () => context.push(AppRoutes.myStore),
              icon: const Icon(Icons.storefront_rounded),
            ),
        ],
      ),
      body: BlocBuilder<StoreCubit, StoreState>(
        builder: (context, state) {
          final cubit = context.read<StoreCubit>();
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    'Tudo o que você compra aqui ajuda a causa de quem vende.',
                    style: TextStyle(color: AppColors.textMuted),
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
                if (state.status == ViewStatus.failure)
                  EmptyState(message: 'Não foi possível carregar a loja.', icon: Icons.cloud_off),
                if (state.status.isLoading || state.status == ViewStatus.initial)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                for (final section in StoreSection.values)
                  if (state.products.any((p) => p.section == section)) ...[
                    SectionHeader(title: section.label),
                    if (!context.isCompact)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AdaptiveCards(
                          children: [
                            for (final p in state.products.where((p) => p.section == section)) _ProductCard(product: p),
                          ],
                        ),
                      )
                    else
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
            ),
          );
        },
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
        width: context.isCompact ? 150 : double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(product: product, height: 130),
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

/// Foto do produto ou ícone sobre fundo claro.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product, required this.height});

  final Product product;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (product.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AppImage(reference: product.imageUrl!, height: height, width: double.infinity),
      );
    }
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Icon(AppIcons.byKey(product.icon), size: height * 0.45, color: AppColors.primary),
      ),
    );
  }
}

/// Loja 3 / Loja 5: detalhe do produto, avaliações e compra.
class ProductPage extends StatefulWidget {
  const ProductPage({super.key, required this.productId});

  final String productId;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late Future<ProductDetail> _detail = context.read<StoreRepository>().detail(widget.productId);

  Future<void> _buy(Product product) async {
    final address = context.currentUser.address;
    final order = await showDialog<(int, String)>(
      context: context,
      builder: (_) => _OrderDialog(
        product: product,
        initialAddress: address == null
            ? ''
            : '${address.street}${address.complement.isEmpty ? '' : ', ${address.complement}'} - '
                  '${address.city}/${address.state} - CEP ${address.cep}',
      ),
    );
    if (order == null || !mounted) return;
    final user = await showCheckout(
      context,
      PaymentIntent.order(productId: product.id, quantity: order.$1, shippingAddress: order.$2),
    );
    if (user == null || !mounted) return;
    context.showMessage('Compra realizada! +20 moedas. A comunidade agradece 💛');
    setState(() => _detail = context.read<StoreRepository>().detail(widget.productId));
    context.read<StoreCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      maxWidth: context.isExpanded ? 960 : Breakpoints.content,
      appBar: AppBar(leading: const AppBackButton(fallback: AppRoutes.store)),
      body: FutureBuilder<ProductDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.hasError) return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
          final detail = snapshot.data;
          if (detail == null) return const Center(child: CircularProgressIndicator());
          final product = detail.product;
          final soldOut = product.stock == 0;
          final mine = product.communityId == context.currentUser.id;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AdaptiveCards(
              minWidth: 340,
              children: [
                ProductImage(product: product, height: 280),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(product.name, style: context.text.headlineSmall),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => context.push(AppRoutes.user(product.communityId)),
                      child: Row(
                        children: [
                          UserAvatar(name: product.communityName, imageUrl: product.sellerAvatarUrl, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.communityName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                          if (product.ratingCount > 0) ...[
                            const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                            Text('${product.rating.toStringAsFixed(1)} (${product.ratingCount})'),
                          ],
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
                    if (product.stock != null)
                      Text(
                        soldOut ? 'Esgotado' : '${product.stock} em estoque',
                        style: TextStyle(color: soldOut ? AppColors.danger : AppColors.textMuted, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      'Comprando você ganha +20 moedas e +30 XP',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    if (mine)
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.editProduct(product.id)),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Editar produto'),
                      )
                    else
                      PrimaryButton(
                        label: soldOut ? 'Esgotado' : 'Comprar',
                        icon: Icons.shopping_bag_outlined,
                        onPressed: soldOut ? null : () => _buy(product),
                      ),
                    if (detail.reviews.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text('Avaliações', style: context.text.titleMedium),
                      for (final r in detail.reviews)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: UserAvatar(name: r.authorName, imageUrl: r.authorAvatarUrl, size: 36),
                          title: Row(
                            children: [
                              for (var i = 0; i < 5; i++)
                                Icon(
                                  i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                            ],
                          ),
                          subtitle: Text(r.comment.isEmpty ? r.authorName : '${r.authorName}: ${r.comment}'),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Quantidade e endereço de entrega antes do pagamento.
class _OrderDialog extends StatefulWidget {
  const _OrderDialog({required this.product, required this.initialAddress});

  final Product product;
  final String initialAddress;

  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  int _quantity = 1;
  late final _address = TextEditingController(text: widget.initialAddress);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = (widget.product.stock ?? 20).clamp(1, 20);
    return AlertDialog(
      title: const Text('Finalizar compra'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Quantidade')),
                IconButton(
                  tooltip: 'Diminuir quantidade',
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_quantity', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  tooltip: 'Aumentar quantidade',
                  onPressed: _quantity < max ? () => setState(() => _quantity++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            TextField(
              controller: _address,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Endereço de entrega (ou "retirar no local")'),
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ${Formatters.currency(widget.product.price * _quantity)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _address.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, (_quantity, _address.text.trim())),
          child: const Text('Ir para o pagamento'),
        ),
      ],
    );
  }
}
