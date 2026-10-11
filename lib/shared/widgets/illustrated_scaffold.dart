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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: context.isExpanded ? _buildSplit(context) : _buildCentered(context),
            ),
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

  /// Telas largas (>= 1024): ilustração à esquerda e cartão à direita,
  /// num bloco central com largura máxima para não esticar na tela toda.
  Widget _buildSplit(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1040),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 5, child: _buildBrandPanel(context)),
            const SizedBox(width: 48),
            Expanded(
              flex: 4,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildCard(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Telas médias (600–1023): coluna única centralizada e legível,
  /// em vez de um cartão estreito perdido num split pela metade.
  Widget _buildCentered(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: _buildCard(context),
    );
  }

  Widget _buildBrandPanel(BuildContext context) {
    return Column(
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
            child: Image.asset(image!, height: 260, fit: BoxFit.contain),
          ),
        ?header,
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    return Card(
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
    );
  }
}
