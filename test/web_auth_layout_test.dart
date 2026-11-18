import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/shared/widgets/web_auth_layout.dart';

void main() {
  for (final width in [360.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('formulário web legível em $width com fonte ampliada', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          home: WebAuthLayout(
            title: 'Crie sua conta',
            description: 'Seu próximo gesto de cuidado começa aqui.',
            showBack: false,
            child: Column(
              children: [
                for (final label in ['E-mail', 'Senha', 'Confirmar senha'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(decoration: InputDecoration(labelText: label)),
                  ),
                FilledButton(onPressed: () {}, child: const Text('Criar conta')),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Criar conta'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Pequenas ações.\nGrandes mudanças.'), width >= 1024 ? findsOneWidget : findsNothing);
      final fieldWidth = tester.getSize(find.byType(TextField).first).width;
      expect(fieldWidth, lessThanOrEqualTo(440));
    });
  }
}
