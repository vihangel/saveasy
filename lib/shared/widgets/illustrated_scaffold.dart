import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

/// Layout das telas de autenticação: faixa laranja com ilustração no topo
/// e o conteúdo num cartão branco arredondado.
class IllustratedScaffold extends StatelessWidget {
  const IllustratedScaffold({
    super.key,
    required this.child,
    this.image,
    this.header,
    this.showBack = true,
    this.onBack,
  });

  /// Asset recortado do Figma (já contém o fundo laranja e a curva do cartão).
  final String? image;

  /// Alternativa ao [image] para cabeçalhos desenhados em código.
  final Widget? header;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.orange,
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 44,
                      child: showBack
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                onPressed: onBack ?? () => context.pop(),
                              ),
                            )
                          : null,
                    ),
                    if (image != null) Image.asset(image!, width: double.infinity, fit: BoxFit.fitWidth),
                    ?header,
                  ],
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), child: child),
          ],
        ),
      ),
    );
  }
}
