import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';

/// Pedidos: compras (avaliar) e, para quem vende, vendas (enviar/entregar/cancelar).
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<StoreOrder>> _bought = _store.myOrders();
  late Future<List<StoreOrder>> _sold = _store.sellerOrders();

  StoreRepository get _store => context.read<StoreRepository>();

  bool get _isSeller => const {AccountType.community, AccountType.business}.contains(context.currentUser.accountType);

  void _reload() => setState(() {
    _bought = _store.myOrders();
    _sold = _store.sellerOrders();
  });

  Future<void> _setStatus(StoreOrder order, OrderStatus status) async {
    try {
      await _store.updateOrderStatus(order.id, status);
      _reload();
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  Future<void> _review(StoreOrder order) async {
    final result = await showDialog<(int, String)>(context: context, builder: (_) => const _ReviewDialog());
    if (result == null || order.productId == null || !mounted) return;
    try {
      await _store.review(order.productId!, rating: result.$1, comment: result.$2);
      if (mounted) context.showMessage('Obrigado pela avaliação!');
      _reload();
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _OrderList(future: _bought, seller: false, onReview: _review, onStatus: _setStatus),
      if (_isSeller) _OrderList(future: _sold, seller: true, onReview: _review, onStatus: _setStatus),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Pedidos'),
          bottom: _isSeller
              ? const TabBar(
                  tabs: [
                    Tab(text: 'Compras'),
                    Tab(text: 'Vendas'),
                  ],
                )
              : null,
        ),
        body: TabBarView(children: tabs),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.future, required this.seller, required this.onReview, required this.onStatus});

  final Future<List<StoreOrder>> future;
  final bool seller;
  final ValueChanged<StoreOrder> onReview;
  final void Function(StoreOrder, OrderStatus) onStatus;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StoreOrder>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
        final orders = snapshot.data;
        if (orders == null) return const Center(child: CircularProgressIndicator());
        if (orders.isEmpty) {
          return EmptyState(
            message: seller ? 'Nenhuma venda ainda.' : 'Você ainda não comprou nada.',
            icon: Icons.receipt_long_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final o = orders[i];
            final other = seller ? o.buyer : o.seller;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${o.quantity}x ${o.productName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(Formatters.currency(o.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Text(
                    '${o.status.label} · ${Formatters.date(o.createdAt.toLocal())}'
                    '${other == null ? '' : ' · ${seller ? 'Para' : 'De'} ${other.name}'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (seller && o.shippingAddress.isNotEmpty)
                    Text('Entrega: ${o.shippingAddress}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (seller && o.status == OrderStatus.paid)
                        FilledButton(
                          onPressed: () => onStatus(o, OrderStatus.shipped),
                          child: const Text('Marcar enviado'),
                        ),
                      if (seller && (o.status == OrderStatus.paid || o.status == OrderStatus.shipped))
                        OutlinedButton(
                          onPressed: () => onStatus(o, OrderStatus.delivered),
                          child: const Text('Marcar entregue'),
                        ),
                      if (seller && o.status == OrderStatus.paid)
                        TextButton(
                          onPressed: () => onStatus(o, OrderStatus.cancelled),
                          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                          child: const Text('Cancelar e reembolsar'),
                        ),
                      if (!seller && !o.reviewed && o.status != OrderStatus.cancelled)
                        OutlinedButton.icon(
                          onPressed: () => onReview(o),
                          icon: const Icon(Icons.star_outline_rounded),
                          label: const Text('Avaliar'),
                        ),
                      if (!seller && o.productId != null)
                        TextButton(
                          onPressed: () => context.push(AppRoutes.product(o.productId!)),
                          child: const Text('Ver produto'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Avaliar produto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: Formatters.plural(i, 'estrela', 'estrelas'),
                  isSelected: i <= _rating,
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(i <= _rating ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.gold),
                ),
            ],
          ),
          TextField(
            controller: _comment,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'Comentário (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_rating, _comment.text.trim())),
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
