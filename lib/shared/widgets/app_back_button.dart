import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';

/// Voltar que sempre funciona: volta na pilha quando existe histórico e, quando
/// a tela foi aberta direto por URL (web, recarregar a página), vai para
/// [fallback].
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.fallback = AppRoutes.home, this.color, this.close = false});

  final String fallback;
  final Color? color;

  /// Mostra um "X" em vez da seta (telas de sucesso e modais).
  final bool close;

  static void goBack(BuildContext context, {String fallback = AppRoutes.home}) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: close ? 'Fechar' : 'Voltar',
      color: color,
      icon: Icon(close ? Icons.close_rounded : Icons.arrow_back_rounded),
      onPressed: () => goBack(context, fallback: fallback),
    );
  }
}
