import 'package:flutter/material.dart';

import '../../app/breakpoints.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import 'app_back_button.dart';

/// Laranja do fundo das ilustrações: o painel usa a mesma cor para a imagem
/// "encaixar" sem emenda.
const _brandOrange = Color(0xFFFA8637);

/// Composição das telas de entrada (login, cadastro, senha, onboarding) na web.
///
/// - Desktop (≥ 1024 px): cartão dividido — painel laranja com a marca e a
///   ilustração à esquerda, formulário à direita.
/// - Tablet e celular no navegador: uma coluna centralizada.
///
/// O layout nativo (apps) continua sendo o `IllustratedScaffold`.
class WebAuthLayout extends StatelessWidget {
  const WebAuthLayout({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    required this.showBack,
    this.onBack,
  });

  final Widget child;
  final String title, description;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final expanded = context.isExpanded;
    final form = _Form(title: title, description: description, showBack: showBack, onBack: onBack, child: child);

    return Theme(
      data: _formTheme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: compact ? Colors.white : const Color(0xFFF4F5FA),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 32, vertical: compact ? 24 : 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: (box.maxHeight - (compact ? 48 : 80)).clamp(0, double.infinity)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: expanded ? 1080 : 480),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [const _Brand(), const SizedBox(height: 32), form],
                          )
                        : _Card(
                            child: expanded
                                ? IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const Expanded(flex: 10, child: _BrandPanel()),
                                        Expanded(
                                          flex: 11,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                                            child: Center(child: form),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [const _Brand(), const SizedBox(height: 32), form],
                                    ),
                                  ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Campos e botões do formulário web: bordas leves, rótulos legíveis.
  static ThemeData _formTheme(ThemeData base) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE0E9)),
    );
    return base.copyWith(
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: Colors.white,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF43485A)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: border,
        border: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(iconSize: 20)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x140F1738), blurRadius: 48, offset: Offset(0, 16))],
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(28), child: child),
  );
}

class _Form extends StatelessWidget {
  const _Form({
    required this.title,
    required this.description,
    required this.showBack,
    required this.onBack,
    required this.child,
  });

  final String title, description;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBack) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(64, 36),
                ),
                onPressed: onBack ?? () => AppBackButton.goBack(context, fallback: AppRoutes.login),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Voltar'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 30, height: 1.2)),
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF5F667A))),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Image.asset('assets/images/logo.png'),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          'Save Easy',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontSize: 22, color: light ? Colors.white : AppColors.textDark),
        ),
      ),
    ],
  );
}

/// Painel laranja: marca, frase, benefícios e a ilustração encostada embaixo.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final headline = Theme.of(context).textTheme.headlineMedium;
    return ColoredBox(
      color: _brandOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 48, 48, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Brand(light: true),
                const SizedBox(height: 40),
                Text(
                  'Pequenas ações.\nGrandes mudanças.',
                  style: headline?.copyWith(fontSize: 36, height: 1.15, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conecte-se a quem faz o bem e descubra novas formas de ajudar a sua comunidade.',
                  style: TextStyle(fontSize: 15, height: 1.6, color: Color(0xF2FFFFFF)),
                ),
                const SizedBox(height: 24),
                const _Benefit(Icons.volunteer_activism_rounded, 'Apoie causas que importam'),
                const SizedBox(height: 12),
                const _Benefit(Icons.groups_rounded, 'Encontre sua comunidade'),
                const SizedBox(height: 12),
                const _Benefit(Icons.emoji_events_rounded, 'Ganhe moedas e acompanhe seu impacto'),
              ],
            ),
          ),
          const Spacer(),
          // Altura fixa: corta só o fundo laranja de cima da ilustração e
          // mantém o cartão baixo o bastante para caber numa tela de notebook.
          ExcludeSemantics(
            child: ClipRect(
              child: SizedBox(
                height: 240,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/welcome_1.png',
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    ],
  );
}
