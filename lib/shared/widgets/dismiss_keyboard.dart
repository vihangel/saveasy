import 'package:flutter/material.dart';

/// Fecha o teclado ao tocar fora de um campo de texto. Botões, campos e
/// listas ganham o gesto antes (estão mais perto do toque), então só um toque
/// em área "vazia" chega aqui.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final focus = FocusManager.instance.primaryFocus;
        if (focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) focus!.unfocus();
      },
      child: child,
    );
  }
}
