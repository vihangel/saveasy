import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/breakpoints.dart';
import '../../app/theme.dart';
import 'app_back_button.dart';

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
    if (!context.isCompact) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF3EA),
        body: SafeArea(
          child: Row(
            children: [
              if (context.isExpanded)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/logo.png', width: 80),
                        const SizedBox(height: 24),
                        Text(
                          'Ações que mudam o mundo',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 24),
                        if (image != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset(image!, height: 280, fit: BoxFit.contain),
                          ),
                        ?header,
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: 420,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showBack)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    tooltip: 'Voltar',
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: onBack ?? () => AppBackButton.goBack(context, fallback: AppRoutes.login),
                                  ),
                                ),
                              child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                                tooltip: 'Voltar',
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                onPressed: onBack ?? () => AppBackButton.goBack(context, fallback: AppRoutes.login),
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
