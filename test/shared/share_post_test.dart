import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/shared/services/share_post.dart';

/// Se o navegador bloquear a área de transferência, o link aparece numa
/// janela em vez de "Não foi possível compartilhar".
void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => sharePostLink(context, '42'), child: const Text('Compartilhar')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Compartilhar'));
    await tester.pumpAndSettle();
  }

  testWidgets('copia o link quando dá', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await open(tester);
    expect(copied, postLink('42'));
    expect(find.text('Link da publicação copiado!'), findsOneWidget);
  });

  testWidgets('mostra o link quando a cópia falha', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') throw PlatformException(code: 'blocked');
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await open(tester);
    expect(find.text('Compartilhar publicação'), findsOneWidget);
    expect(find.text(postLink('42')), findsOneWidget);
  });
}
