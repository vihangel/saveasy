import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';

/// Painel financeiro: doações recebidas, inscrições, vendas e repasses.
class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late Future<FinanceSummary> _summary = context.read<WalletRepository>().finance();

  Future<void> _payout(FinanceSummary summary) async {
    final amount = TextEditingController(text: summary.available.toStringAsFixed(2).replaceAll('.', ','));
    final pix = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pedir repasse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: r'Valor (R$)'),
            ),
            TextField(
              controller: pix,
              decoration: const InputDecoration(labelText: 'Chave Pix'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pedir')),
        ],
      ),
    );
    if (!(ok ?? false) || !mounted) return;
    try {
      final updated = context.read<WalletRepository>().requestPayout(
        amount: double.tryParse(amount.text.replaceAll(',', '.')) ?? 0,
        pixKey: pix.text,
      );
      await updated;
      if (!mounted) return;
      setState(() => _summary = updated);
      context.showMessage('Repasse solicitado. O pagamento é feito em até 2 dias úteis.');
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Painel financeiro')),
      body: FutureBuilder<FinanceSummary>(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.hasError) return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
          final s = snapshot.data;
          if (s == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Disponível para repasse', style: TextStyle(color: Colors.white70)),
                    Text(
                      Formatters.currency(s.available),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    if (s.feePercent > 0)
                      Text(
                        'Já descontada a taxa da plataforma (${s.feePercent.toStringAsFixed(1)}%)',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: s.available >= 10 ? () => _payout(s) : null,
                      child: const Text('Pedir repasse via Pix'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Line(
                icon: Icons.volunteer_activism_rounded,
                label: 'Doações em dinheiro',
                value: Formatters.currency(s.donations),
              ),
              _Line(
                icon: Icons.monetization_on_rounded,
                label: 'Doações com moedas (fundo)',
                value: Formatters.currency(s.donationsFromCoins),
              ),
              _Line(icon: Icons.numbers_rounded, label: 'Número de doações', value: '${s.donationsCount}'),
              _Line(
                icon: Icons.groups_rounded,
                label: 'Inscrições (${s.activeSubscribers} ativas)',
                value: Formatters.currency(s.subscriptions),
              ),
              _Line(
                icon: Icons.storefront_rounded,
                label: 'Vendas (${s.salesCount})',
                value: Formatters.currency(s.sales),
              ),
              if (s.ordersToShip > 0)
                _Line(icon: Icons.local_shipping_rounded, label: 'Pedidos para enviar', value: '${s.ordersToShip}'),
              _Line(icon: Icons.outbox_rounded, label: 'Repasses pedidos/pagos', value: Formatters.currency(s.payouts)),
              if (s.payoutHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Repasses', style: Theme.of(context).textTheme.titleMedium),
                for (final p in s.payoutHistory)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(Formatters.currency(p.amount)),
                    subtitle: Text(Formatters.date(p.createdAt.toLocal())),
                    trailing: Text(switch (p.status) {
                      'paid' => 'Pago',
                      'rejected' => 'Recusado',
                      _ => 'Em análise',
                    }),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.orange),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
