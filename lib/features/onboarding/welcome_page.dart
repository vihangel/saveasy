import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/breakpoints.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/legal_texts.dart';
import '../../shared/utils/links.dart';

/// Boas vindas 1, 2 e 3.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    (
      'assets/images/welcome_1.png',
      'Ações que mudam o mundo',
      'Se você não sabia como ajudar o próximo de maneira simples, agora você tem a solução perfeita.',
    ),
    (
      'assets/images/welcome_2.png',
      'Comece a ajudar',
      'Faça doações, crie eventos beneficentes, mostre suas ações sociais, plante uma árvore, doe sangue, e mais centenas de opções. Não importa como, sempre terá uma forma de ajudar.',
    ),
    (
      'assets/images/welcome_3.png',
      'Personalize',
      'Ganhe pontos e níveis enquanto ajuda. Troque esses pontos por itens personalizáveis incríveis, seja capa, selos ou títulos. Apoie uma comunidade e siga seus influencers favoritos para desbloquear itens personalizáveis diretamente deles.',
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      // O router leva para o login quando o onboarding é concluído.
      context.read<SessionCubit>().completeOnboarding();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isCompact) return _WebWelcome(slides: _slides);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final (image, title, body) = _slides[i];
                // Rolável para caber em telas pequenas ou com fonte grande.
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        color: AppColors.orange,
                        width: double.infinity,
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Image.asset(image, width: double.infinity, fit: BoxFit.fitWidth),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 16),
                            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
              child: _isLast
                  ? FilledButton(onPressed: _next, child: const Text('Começar'))
                  : TextButton(onPressed: _next, child: const Text('Avançar')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boas-vindas na web (tablet e desktop): página de entrada com barra
/// superior, destaque, "como funciona" e rodapé — o carrossel é do celular.
class _WebWelcome extends StatelessWidget {
  const _WebWelcome({required this.slides});

  final List<(String, String, String)> slides;

  static const _cream = Color(0xFFFFF3EA);
  static const _maxWidth = 1160.0;

  /// Marca o onboarding como visto; o router leva ao login.
  Future<void> _enter(BuildContext context) => context.read<SessionCubit>().completeOnboarding();

  Future<void> _signUp(BuildContext context) async {
    final router = GoRouter.of(context);
    await context.read<SessionCubit>().completeOnboarding();
    router.go(AppRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    final expanded = context.isExpanded;
    final text = Theme.of(context).textTheme;
    const buttonSize = Size(150, 52);

    Widget section({required Widget child, Color? color, EdgeInsets? padding}) => ColoredBox(
      color: color ?? Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Padding(padding: padding ?? const EdgeInsets.symmetric(horizontal: 32), child: child),
        ),
      ),
    );

    final heroText = Column(
      crossAxisAlignment: expanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const Text(
            'Doações, eventos e ações sociais',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.orange),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Faça o bem.\nTransforme sua comunidade.',
          textAlign: expanded ? TextAlign.start : TextAlign.center,
          style: text.headlineMedium?.copyWith(fontSize: expanded ? 52 : 40, height: 1.1),
        ),
        const SizedBox(height: 20),
        Text(
          'Encontre campanhas perto de você, participe de ações, doe por Pix ou com moedas '
          'e acompanhe o impacto de cada gesto.',
          textAlign: expanded ? TextAlign.start : TextAlign.center,
          style: const TextStyle(fontSize: 17, height: 1.6, color: AppColors.text),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: buttonSize),
              onPressed: () => _signUp(context),
              child: const Text('Criar conta'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: buttonSize, backgroundColor: Colors.white),
              onPressed: () => _enter(context),
              child: const Text('Já tenho conta'),
            ),
          ],
        ),
      ],
    );

    final heroImage = ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(slides.first.$1, fit: BoxFit.cover),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Barra superior.
              section(
                color: _cream,
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
                child: Row(
                  children: [
                    Image.asset('assets/images/logo.png', width: 40),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Save Easy', style: text.titleLarge?.copyWith(fontSize: 22))),
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(88, 44)),
                      onPressed: () => _enter(context),
                      child: const Text('Entrar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(132, 44)),
                      onPressed: () => _signUp(context),
                      child: const Text('Criar conta'),
                    ),
                  ],
                ),
              ),
              // Destaque.
              section(
                color: _cream,
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 72),
                child: expanded
                    ? Row(
                        children: [
                          Expanded(flex: 6, child: heroText),
                          const SizedBox(width: 56),
                          Expanded(flex: 5, child: heroImage),
                        ],
                      )
                    : Column(
                        children: [
                          heroText,
                          const SizedBox(height: 40),
                          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: heroImage),
                        ],
                      ),
              ),
              // Como funciona.
              section(
                padding: const EdgeInsets.fromLTRB(32, 72, 32, 72),
                child: Column(
                  children: [
                    Text(
                      'Como funciona',
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tudo o que você precisa para ajudar, num lugar só.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 40),
                    if (expanded)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < slides.length; i++) ...[
                              if (i > 0) const SizedBox(width: 24),
                              Expanded(
                                child: _FeatureCard(step: i + 1, slide: slides[i]),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      for (var i = 0; i < slides.length; i++) ...[
                        if (i > 0) const SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _FeatureCard(step: i + 1, slide: slides[i]),
                        ),
                      ],
                  ],
                ),
              ),
              // Rodapé.
              const Divider(height: 1, color: AppColors.border),
              section(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text('© ${DateTime.now().year} Save Easy', style: const TextStyle(color: AppColors.textMuted)),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => context.push(AppRoutes.transparency),
                          child: const Text('Transparência'),
                        ),
                        TextButton(
                          onPressed: () => openExternalLink(LegalTexts.privacyUrl),
                          child: const Text('Privacidade'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.step, required this.slide});

  final int step;
  final (String, String, String) slide;

  @override
  Widget build(BuildContext context) {
    final (image, title, body) = slide;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1056 / 828,
                  child: Image.asset(image, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Passo $step',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.orange),
            ),
            const SizedBox(height: 6),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}
