import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/shared/widgets/dismiss_keyboard.dart';

void main() {
  testWidgets('toque fora fecha o teclado; toque em campo ou botão não', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DismissKeyboard(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              const TextField(key: Key('a')),
              const TextField(key: Key('b')),
              TextButton(onPressed: () => pressed++, child: const Text('botão')),
              const SizedBox(key: Key('vazio'), height: 200, width: 200),
            ],
          ),
        ),
      ),
    );
    bool focused() =>
        FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;

    await tester.tap(find.byKey(const Key('a')));
    await tester.pump();
    expect(focused(), isTrue);

    await tester.tap(find.byKey(const Key('b')));
    await tester.pump();
    expect(focused(), isTrue);

    await tester.tap(find.text('botão'));
    await tester.pump();
    expect(pressed, 1);
    expect(focused(), isTrue);

    await tester.tap(find.byKey(const Key('vazio')), warnIfMissed: false);
    await tester.pump();
    expect(focused(), isFalse);
  });
}
