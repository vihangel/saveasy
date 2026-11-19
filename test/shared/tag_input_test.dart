import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/shared/widgets/tag_input.dart';

/// O texto digitado vira tag com Enter, vírgula ou ao sair do campo
/// (antes só com Enter, e o texto se perdia).
void main() {
  Future<List<String>> pump(WidgetTester tester, Future<void> Function() act) async {
    var tags = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                TagInput(tags: tags, onChanged: (v) => setState(() => tags = v)),
                const TextField(key: Key('outro')),
              ],
            ),
          ),
        ),
      ),
    );
    await act();
    return tags;
  }

  testWidgets('Enter adiciona', (tester) async {
    final tags = await pump(tester, () async {
      await tester.enterText(find.byType(TextField).first, 'animais');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    });
    expect(tags, ['animais']);
  });

  testWidgets('vírgula separa', (tester) async {
    final tags = await pump(tester, () async {
      await tester.enterText(find.byType(TextField).first, 'animais, adoção,');
      await tester.pump();
    });
    expect(tags, ['animais', 'adoção']);
  });

  testWidgets('sair do campo não perde o texto', (tester) async {
    final tags = await pump(tester, () async {
      await tester.enterText(find.byType(TextField).first, '#mutirão');
      await tester.tap(find.byKey(const Key('outro')));
      await tester.pump();
    });
    expect(tags, ['mutirão']);
  });
}
