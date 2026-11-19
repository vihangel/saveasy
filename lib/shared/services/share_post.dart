import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/env.dart';
import '../utils/context_x.dart';

String postLink(String id) => Uri.parse(Env.webRedirectUrl).resolve('post/${Uri.encodeComponent(id)}').toString();

/// Copia o link da publicação. Se o navegador bloquear a área de
/// transferência (acontece fora de um clique direto ou sem foco), mostra o
/// link numa janela para a pessoa copiar — antes isso virava
/// "Não foi possível compartilhar".
Future<void> sharePostLink(BuildContext context, String id) async {
  final link = postLink(id);
  try {
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) context.showMessage('Link da publicação copiado!');
  } catch (_) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartilhar publicação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copie o link abaixo e envie para quem você quiser:'),
            const SizedBox(height: 12),
            SelectableText(link, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await Clipboard.setData(ClipboardData(text: link));
                navigator.pop();
                messenger.showSnackBar(const SnackBar(content: Text('Link copiado!')));
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Selecione o link e copie com Ctrl+C (ou Cmd+C).')),
                );
              }
            },
            child: const Text('Copiar link'),
          ),
        ],
      ),
    );
  }
}
