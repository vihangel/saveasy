import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';

/// Página pública: fundo de doações e números da plataforma (sem dados pessoais).
class TransparencyPage extends StatefulWidget {
  const TransparencyPage({super.key});

  @override
  State<TransparencyPage> createState() => _TransparencyPageState();
}

class _TransparencyPageState extends State<TransparencyPage> {
  late final Future<Transparency> _data = context.read<ModerationRepository>().transparency();

  static const _kinds = {
    'platform_contribution': 'Aporte da plataforma',
    'ad_share': '30% de anúncio',
    'coin_donation': 'Doação com moedas',
    'adjustment': 'Ajuste',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.home),
        title: const Text('Transparência'),
      ),
      body: FutureBuilder<Transparency>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
          final t = snapshot.data;
          if (t == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo do fundo de doações', style: TextStyle(color: Colors.white70)),
                    Text(
                      Formatters.currency(t.fund.balance),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Entrou ${Formatters.currency(t.fund.received)} · saiu ${Formatters.currency(t.fund.paidOut)} '
                      'para campanhas · ${t.fund.coinsPerReal} moedas = R\$ 1',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Box(label: 'Doado às campanhas', value: Formatters.currency(t.donationsTotal)),
                  _Box(label: 'Doações', value: Formatters.number(t.donationsCount)),
                  _Box(label: 'Campanhas', value: Formatters.number(t.campaigns)),
                  _Box(label: 'Ações e eventos', value: Formatters.number(t.actions)),
                  _Box(label: 'Voluntários', value: Formatters.number(t.volunteers)),
                  _Box(label: 'Vindo de anúncios', value: Formatters.currency(t.adShare)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Movimentações do fundo', style: Theme.of(context).textTheme.titleMedium),
              for (final m in t.movements)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_kinds[m.kind] ?? m.kind),
                  subtitle: Text('${Formatters.date(m.createdAt.toLocal())}${m.note == null ? '' : ' · ${m.note}'}'),
                  trailing: Text(
                    Formatters.currency(m.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: m.amount >= 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(child: Text(value, style: Theme.of(context).textTheme.titleLarge)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
