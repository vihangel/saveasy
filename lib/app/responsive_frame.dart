import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../shared/data/datasources/mock_seed.dart';
import 'theme.dart';

/// Adapta o app (desenhado para celular) a telas largas, como o navegador no
/// desktop:
///
/// - até [mobileBreakpoint]: ocupa a tela inteira, como no celular;
/// - acima disso: o app fica numa coluna central com largura de celular;
/// - a partir de [wideBreakpoint]: mostra também um painel de apresentação.
///
/// O [MediaQuery] é reescrito com a largura da coluna, então telas, diálogos e
/// bottom sheets se comportam como num celular.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child});

  final Widget child;

  static const mobileBreakpoint = 600.0;
  static const wideBreakpoint = 1000.0;
  static const appWidth = 430.0;
  static const _maxAppHeight = 932.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    if (size.width < mobileBreakpoint) return child;

    // Com altura suficiente o app aparece como um "celular" com bordas
    // arredondadas; em janelas baixas usa a altura toda.
    final framed = size.height >= 700;
    final appHeight = framed ? math.min(size.height - 48, _maxAppHeight) : size.height;
    final wide = size.width >= wideBreakpoint;

    final app = SizedBox(
      width: appWidth,
      height: appHeight,
      child: MediaQuery(
        data: media.copyWith(size: Size(appWidth, appHeight), padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(framed ? 28 : 0),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 12))],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(framed ? 28 : 0), child: child),
        ),
      ),
    );

    // Material: o painel lateral fica fora do Navigator e precisa dele para
    // os estilos de texto.
    return Material(
      color: const Color(0xFFFFF3EA),
      child: Stack(
        children: [
          // Fundo com formas nas cores da marca.
          const Positioned(top: -120, left: -80, child: _Blob(size: 360, color: Color(0x33FA7E2A))),
          const Positioned(bottom: -140, right: -60, child: _Blob(size: 420, color: Color(0x266176ED))),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (wide) ...[const _SidePanel(), const SizedBox(width: 72)],
                app,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Apresentação do projeto ao lado do app no desktop.
class _SidePanel extends StatelessWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/logo.png', width: 56),
              const SizedBox(width: 12),
              Text('SavEasy', style: text.headlineMedium?.copyWith(color: AppColors.primary, fontSize: 32)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Ações que mudam o mundo', style: text.headlineSmall?.copyWith(fontSize: 28)),
          const SizedBox(height: 12),
          const Text(
            'Doe, participe de eventos e ações sociais, ganhe moedas e níveis enquanto ajuda '
            'e troque por itens personalizados.',
            style: TextStyle(fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conta de teste',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                SizedBox(height: 6),
                Text('${MockSeed.demoEmail}  ·  senha ${MockSeed.demoPassword}'),
                SizedBox(height: 4),
                Text(
                  'Código de verificação: ${MockSeed.verificationCode}',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Protótipo com dados simulados. O que você fizer fica salvo só neste navegador.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// No web/desktop permite arrastar listas e carrosséis com o mouse (por
/// padrão o Flutter só arrasta com toque) e mostra barras de rolagem.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
