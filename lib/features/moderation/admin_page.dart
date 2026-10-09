import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/utils/links.dart';
import '../../shared/widgets/widgets.dart';

/// Painel da equipe (admin/moderador): resumo, denúncias, verificações,
/// anúncios em análise e repasses.
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  ModerationRepository get _repo => context.read<ModerationRepository>();

  late Future<AdminDashboard> _dashboard = _repo.dashboard();
  late Future<List<AdminReport>> _reports = _repo.reports();
  late Future<List<VerificationRequest>> _verifications = _repo.verifications();
  late Future<List<AdCampaign>> _ads = _repo.adsInReview();
  late Future<List<PayoutRequest>> _payouts = _repo.payouts();

  void _reload() => setState(() {
    _dashboard = _repo.dashboard();
    _reports = _repo.reports();
    _verifications = _repo.verifications();
    _ads = _repo.adsInReview();
    _payouts = _repo.payouts();
  });

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      _reload();
      if (mounted) context.showMessage(success);
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  /// Pede uma observação (opcional) antes de uma ação. `null` = cancelou.
  Future<String?> _note(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Observação (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Confirmar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.currentUser.isStaff) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: const EmptyState(message: 'Acesso restrito à equipe do Save Easy.', icon: Icons.lock_outline),
      );
    }
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Painel da equipe'),
          actions: [IconButton(tooltip: 'Atualizar', onPressed: _reload, icon: const Icon(Icons.refresh_rounded))],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Denúncias'),
              Tab(text: 'Verificações'),
              Tab(text: 'Anúncios'),
              Tab(text: 'Repasses'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Async<AdminDashboard>(
              future: _dashboard,
              builder: (d) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _Line('Denúncias abertas', '${d.openReports}'),
                  _Line('Verificações pendentes', '${d.pendingVerifications}'),
                  _Line('Anúncios em análise', '${d.adsInReview}'),
                  _Line('Repasses pedidos', '${d.payoutsRequested}'),
                  const Divider(),
                  _Line('Usuários (sem demo)', '${d.users}'),
                  _Line('Publicações', '${d.posts}'),
                  _Line('Doado às campanhas', Formatters.currency(d.donations)),
                  _Line('Saldo do fundo', Formatters.currency(d.fund.balance)),
                ],
              ),
            ),
            _Async<List<AdminReport>>(
              future: _reports,
              empty: 'Nenhuma denúncia aberta.',
              builder: (reports) => ListView.separated(
                itemCount: reports.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = reports[i];
                  final p = r.preview;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.reason.label} · ${r.targetType.name} · ${r.reportsOnTarget} denúncia(s)',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Por ${r.reporterName ?? 'conta excluída'} · ${Formatters.relative(r.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        if (r.details.isNotEmpty) Text('"${r.details}"'),
                        if (p != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (p.text.isNotEmpty) Text(p.text, maxLines: 4, overflow: TextOverflow.ellipsis),
                                if (p.authorName != null)
                                  Text('Autor: ${p.authorName}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          )
                        else
                          const Text('Conteúdo já removido.', style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (r.targetType == ReportTarget.post)
                              TextButton(
                                onPressed: () => context.push(AppRoutes.post(r.targetId)),
                                child: const Text('Abrir'),
                              ),
                            if (p?.authorId != null)
                              TextButton(
                                onPressed: () => context.push(AppRoutes.user(p!.authorId!)),
                                child: const Text('Ver autor'),
                              ),
                            for (final action in ModerationAction.values)
                              OutlinedButton(
                                onPressed: () async {
                                  final note = await _note(action.label);
                                  if (note != null) {
                                    await _run(() => _repo.resolve(r.id, action, note: note), 'Denúncia resolvida.');
                                  }
                                },
                                style: action == ModerationAction.dismiss
                                    ? null
                                    : OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                child: Text(action.label),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _Async<List<VerificationRequest>>(
              future: _verifications,
              empty: 'Nenhuma verificação pendente.',
              builder: (items) => ListView(
                children: [
                  for (final v in items)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${v.profile.name} (@${v.profile.username})',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text('${v.legalName} · ${v.documentNumber} · ${v.profile.accountType.label}'),
                          if (v.notes.isNotEmpty) Text(v.notes, style: const TextStyle(color: AppColors.textMuted)),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await openExternalLink(await _repo.documentUrl(v.documentPath));
                                  } on AppException catch (e) {
                                    if (context.mounted) context.showMessage(e.message, error: true);
                                  }
                                },
                                child: const Text('Ver documento'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    _run(() => _repo.reviewVerification(v.id, approve: true), 'Conta verificada.'),
                                child: const Text('Aprovar'),
                              ),
                              OutlinedButton(
                                onPressed: () async {
                                  final note = await _note('Motivo da recusa');
                                  if (note != null) {
                                    await _run(
                                      () => _repo.reviewVerification(v.id, approve: false, note: note),
                                      'Pedido recusado.',
                                    );
                                  }
                                },
                                child: const Text('Recusar'),
                              ),
                            ],
                          ),
                          const Divider(),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _Async<List<AdCampaign>>(
              future: _ads,
              empty: 'Nenhum anúncio em análise.',
              builder: (ads) => ListView(
                children: [
                  for (final c in ads)
                    ListTile(
                      title: Text(c.title),
                      subtitle: Text(
                        '${c.ownerName} · ${c.format.label} · ${c.plan.label} · ${Formatters.currency(c.price)}'
                        '${c.body.isEmpty ? '' : '\n${c.body}'}',
                      ),
                      isThreeLine: c.body.isNotEmpty,
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Aprovar',
                            onPressed: () => _run(() => _repo.reviewAd(c.id, approve: true), 'Anúncio no ar.'),
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                          ),
                          IconButton(
                            tooltip: 'Recusar e reembolsar',
                            onPressed: () async {
                              final note = await _note('Motivo da recusa');
                              if (note != null) {
                                await _run(
                                  () => _repo.reviewAd(c.id, approve: false, note: note),
                                  'Anúncio recusado e reembolsado.',
                                );
                              }
                            },
                            icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _Async<List<PayoutRequest>>(
              future: _payouts,
              empty: 'Nenhum repasse pedido.',
              builder: (payouts) => ListView(
                children: [
                  for (final p in payouts)
                    ListTile(
                      title: Text('${Formatters.currency(p.amount)} · ${p.profile.name}'),
                      subtitle: Text('Pix: ${p.pixKey} · ${Formatters.date(p.createdAt.toLocal())}'),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Marcar como pago',
                            onPressed: () =>
                                _run(() => _repo.setPayout(p.id, paid: true), 'Repasse marcado como pago.'),
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                          ),
                          IconButton(
                            tooltip: 'Recusar',
                            onPressed: () async {
                              final note = await _note('Motivo');
                              if (note != null) {
                                await _run(() => _repo.setPayout(p.id, paid: false, note: note), 'Repasse recusado.');
                              }
                            },
                            icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Async<T> extends StatelessWidget {
  const _Async({required this.future, required this.builder, this.empty});

  final Future<T> future;
  final Widget Function(T data) builder;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
        final data = snapshot.data;
        if (data == null) return const Center(child: CircularProgressIndicator());
        if (empty != null && data is List && data.isEmpty) {
          return EmptyState(message: empty!, icon: Icons.check_circle_outline);
        }
        return builder(data);
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
