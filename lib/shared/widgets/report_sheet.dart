import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../utils/context_x.dart';

/// Denunciar conteúdo ou perfil. A equipe analisa no painel de moderação.
Future<void> showReportSheet(BuildContext context, ReportTarget target, String targetId) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReportSheet(target: target, targetId: targetId),
  );
  if ((sent ?? false) && context.mounted) {
    context.showMessage('Denúncia enviada. Obrigado por ajudar a manter o Save Easy seguro.');
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.target, required this.targetId});

  final ReportTarget target;
  final String targetId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await context.read<ModerationRepository>().report(
        widget.target,
        widget.targetId,
        _reason!,
        details: _details.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      context.showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Denunciar', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Quem publicou não fica sabendo quem denunciou.'),
              RadioGroup<ReportReason>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: [
                    for (final r in ReportReason.values)
                      RadioListTile<ReportReason>(contentPadding: EdgeInsets.zero, value: r, title: Text(r.label)),
                  ],
                ),
              ),
              TextField(
                controller: _details,
                maxLength: 1000,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Detalhes (opcional)'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _reason == null || _sending ? null : _send,
                  child: Text(_sending ? 'Enviando...' : 'Enviar denúncia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
