import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/utils/validators.dart';

/// Comunidade gerencia os planos de inscrição (apoiadores).
class PlansEditorPage extends StatefulWidget {
  const PlansEditorPage({super.key});

  @override
  State<PlansEditorPage> createState() => _PlansEditorPageState();
}

class _PlansEditorPageState extends State<PlansEditorPage> {
  late Future<CommunityPlans> _plans = _wallet.communityPlans(context.currentUser.id);

  WalletRepository get _wallet => context.read<WalletRepository>();

  Future<void> _edit([SubscriptionPlan? plan]) async {
    final result = await showDialog<(SubscriptionPlan, bool)>(
      context: context,
      builder: (_) => _PlanDialog(plan: plan),
    );
    if (result == null || !mounted) return;
    try {
      final updated = _wallet.savePlan(result.$1, active: result.$2);
      await updated;
      if (!mounted) return;
      setState(() => _plans = updated);
      context.showMessage(result.$2 ? 'Plano salvo.' : 'Plano desativado.');
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Planos de inscrição')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Plano'),
      ),
      body: FutureBuilder<CommunityPlans>(
        future: _plans,
        builder: (context, snapshot) {
          if (snapshot.hasError) return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
          final data = snapshot.data;
          if (data == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '${data.subscribers} apoiador(es) ativo(s). Quem já assinou continua no plano até o fim do período.',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              if (data.plans.isEmpty) const EmptyState(message: 'Nenhum plano ativo.', icon: Icons.workspace_premium),
              for (final p in data.plans)
                ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    '${Formatters.currency(p.price)} a cada ${p.months == 1 ? 'mês' : '${p.months} meses'}'
                    '${p.benefits.isEmpty ? '' : '\n${p.benefits}'}',
                  ),
                  isThreeLine: p.benefits.isNotEmpty,
                  trailing: const Icon(Icons.edit_rounded),
                  onTap: () => _edit(p),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PlanDialog extends StatefulWidget {
  const _PlanDialog({this.plan});

  final SubscriptionPlan? plan;

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  late final _name = TextEditingController(text: widget.plan?.name ?? '');
  late final _price = TextEditingController(text: widget.plan?.price.toStringAsFixed(2).replaceAll('.', ',') ?? '');
  late final _benefits = TextEditingController(text: widget.plan?.benefits ?? '');
  late int _months = widget.plan?.months ?? 1;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _price, _benefits]) {
      c.dispose();
    }
    super.dispose();
  }

  SubscriptionPlan get _plan => SubscriptionPlan(
    id: widget.plan?.id ?? '',
    name: _name.text,
    price: Validators.parseMoney(_price.text) ?? 0,
    months: _months,
    benefits: _benefits.text,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.plan == null ? 'Novo plano' : 'Editar plano'),
      content: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome (ex.: Mensal)'),
            ),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
              decoration: const InputDecoration(labelText: r'Preço (R$)'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _months,
              decoration: const InputDecoration(labelText: 'Cobrança'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Mensal')),
                DropdownMenuItem(value: 3, child: Text('Trimestral')),
                DropdownMenuItem(value: 6, child: Text('Semestral')),
                DropdownMenuItem(value: 12, child: Text('Anual')),
              ],
              onChanged: (v) => setState(() => _months = v ?? 1),
            ),
            TextField(
              controller: _benefits,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Benefícios para quem apoia'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
          ],
        ),
      ),
      actions: [
        if (widget.plan != null)
          TextButton(
            onPressed: () => Navigator.pop(context, (_plan, false)),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Desativar'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final error = _name.text.trim().isEmpty
                ? 'Dê um nome ao plano.'
                : (_plan.price <= 0 ? 'Informe o preço.' : null);
            if (error != null) return setState(() => _error = error);
            Navigator.pop(context, (_plan, true));
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
