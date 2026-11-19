import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saveeasy2026/app/app.dart';
import 'package:saveeasy2026/app/dependencies.dart';
import 'package:saveeasy2026/shared/data/datasources/image_storage.dart';

import 'helpers/test_database.dart';

/// O link "termos de uso" abre o texto (antes só marcava a caixa) e
/// "Li e concordo" no fim marca o aceite.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    testWidgets('termos de uso abrem o texto em ${size.width}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final (db, storage) = await createTestDatabase();
      await storage.writeBool('onboarding_seen', true);
      await tester.pumpWidget(SaveEasyApp(deps: AppDependencies.mock(db, storage, images: ImageStorage.forTesting())));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      GoRouter.of(tester.element(find.byType(Navigator).first)).go('/signup');
      await tester.pumpAndSettle();

      Checkbox box() => tester.widget<Checkbox>(find.byType(Checkbox));
      expect(box().value, isFalse);

      await tester.ensureVisible(find.text('termos de uso'));
      await tester.tap(find.text('termos de uso'));
      await tester.pumpAndSettle();
      expect(find.text('Li e concordo'), findsOneWidget);
      expect(box().value, isFalse, reason: 'abrir os termos não pode marcar o aceite sozinho');

      await tester.ensureVisible(find.text('Li e concordo'));
      await tester.tap(find.text('Li e concordo'));
      await tester.pumpAndSettle();
      expect(box().value, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
