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

/// Gerenciador de anúncios: campanhas, métricas, pausar e pagar.
class AdsPage extends StatefulWidget {
  const AdsPage({super.key});

  @override
  State<AdsPage> createState() => _AdsPageState();
}

class _AdsPageState extends State<AdsPage> {
  late Future<List<AdCampaign>> _campaigns = _repo.myCampaigns();

  AdsRepository get _repo => context.read<AdsRepository>();

  void _reload() => setState(() => _campaigns = _repo.myCampaigns());

  Future<void> _run(Future<void> Function() action, [String? success]) async {
    try {
      await action();
      _reload();
      if (mounted && success != null) context.showMessage(success);
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  Future<void> _pay(AdCampaign c) async {
    final user = await showCheckout(context, PaymentIntent.adCampaign(campaignId: c.id));
    if (user == null || !mounted) return;
    _reload();
    context.showMessage(
      user.verificationStatus == 'verified'
          ? 'Pago! Sua campanha já está no ar.'
          : 'Pago! A campanha entra no ar depois da análise (até 24 h).',
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAdvertise = context.currentUser.accountType != AccountType.personal;
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Anúncios')),
      floatingActionButton: canAdvertise
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push(AppRoutes.newAd);
                _reload();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova campanha'),
            )
          : null,
      body: !canAdvertise
          ? const EmptyState(
              message:
                  'Anúncios são para empresas, influenciadores e comunidades. '
                  'Mude o tipo de conta em Configurações para anunciar.',
              icon: Icons.campaign_outlined,
            )
          : FutureBuilder<List<AdCampaign>>(
              future: _campaigns,
              builder: (context, snapshot) {
                if (snapshot.hasError) return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
                final campaigns = snapshot.data;
                if (campaigns == null) return const Center(child: CircularProgressIndicator());
                if (campaigns.isEmpty) {
                  return const EmptyState(
                    message: 'Crie sua primeira campanha. 30% do valor vai para o fundo de doações de Cuiabá.',
                    icon: Icons.campaign_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100, top: 8),
                  itemCount: campaigns.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = campaigns[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              Chip(label: Text(c.status.label), visualDensity: VisualDensity.compact),
                            ],
                          ),
                          Text(
                            '${c.format.label} · ${c.plan.label} · ${Formatters.currency(c.price)}'
                            '${c.cities.isEmpty ? '' : ' · ${c.cities.join(', ')}'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          if (c.endsAt != null)
                            Text(
                              'Até ${Formatters.date(c.endsAt!.toLocal())}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          if (c.reviewNote != null && c.reviewNote!.isNotEmpty)
                            Text(
                              'Análise: ${c.reviewNote}',
                              style: const TextStyle(fontSize: 12, color: AppColors.danger),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Metric(label: 'Impressões', value: Formatters.compact(c.impressions)),
                              _Metric(label: 'Cliques', value: Formatters.compact(c.clicks)),
                              _Metric(label: 'CTR', value: '${(c.ctr * 100).toStringAsFixed(1)}%'),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (c.status == AdStatus.pendingPayment) ...[
                                FilledButton(onPressed: () => _pay(c), child: const Text('Pagar')),
                                TextButton(
                                  onPressed: () => _run(() => _repo.delete(c.id), 'Campanha removida.'),
                                  child: const Text('Excluir'),
                                ),
                              ],
                              if (c.status == AdStatus.active)
                                OutlinedButton(
                                  onPressed: () => _run(() => _repo.setPaused(c.id, paused: true), 'Campanha pausada.'),
                                  child: const Text('Pausar'),
                                ),
                              if (c.status == AdStatus.paused)
                                OutlinedButton(
                                  onPressed: () =>
                                      _run(() => _repo.setPaused(c.id, paused: false), 'Campanha retomada.'),
                                  child: const Text('Retomar'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
