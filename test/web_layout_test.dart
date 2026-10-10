import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saveeasy2026/app/app.dart';
import 'package:saveeasy2026/app/breakpoints.dart';
import 'package:saveeasy2026/app/dependencies.dart';
import 'package:saveeasy2026/shared/data/datasources/image_storage.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/widgets/adaptive_sheet.dart';

import 'helpers/test_database.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final size in [const Size(360, 640), const Size(768, 1024), const Size(1440, 900)]) {
    testWidgets('seletor adaptativo em ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showAdaptiveSheet<String>(
                    context: context,
                    builder: (context) => TextButton(
                      onPressed: () => Navigator.pop(context, 'escolhido'),
                      child: const Text('Confirmar'),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(size.width < Breakpoints.medium ? BottomSheet : Dialog), findsOneWidget);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(result, 'escolhido');
    });
  }

  testWidgets('navegação e rascunho sobrevivem ao redimensionamento', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.reset);
    final (db, storage) = await createTestDatabase();
    await storage.writeString('session_user_id', MockSeed.demoUserId);
    await tester.pumpWidget(SaveEasyApp(deps: AppDependencies.mock(db, storage, images: ImageStorage.forTesting())));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(BottomAppBar), findsOneWidget);
    final router = GoRouter.of(tester.element(find.byType(Navigator).first));
    router.go('/create/discussion');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.enterText(find.byType(TextField).first, 'Rascunho preservado');
    for (final size in [const Size(768, 1024), const Size(1440, 900), const Size(360, 640)]) {
      tester.view.physicalSize = size;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Rascunho preservado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
