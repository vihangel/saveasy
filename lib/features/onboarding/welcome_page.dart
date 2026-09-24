import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../shared/notifiers/session_cubit.dart';

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
