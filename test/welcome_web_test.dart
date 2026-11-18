import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saveeasy2026/app/app.dart';
import 'package:saveeasy2026/app/dependencies.dart';
import 'package:saveeasy2026/features/auth/login/login_page.dart';
import 'package:saveeasy2026/features/auth/sign_up/sign_up_pages.dart';
import 'package:saveeasy2026/shared/data/datasources/image_storage.dart';

import 'helpers/test_database.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final label in ['Entrar', 'Já tenho conta', 'Criar conta']) {
    testWidgets('boas-vindas web: "$label" leva à tela certa', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      final (db, storage) = await createTestDatabase();
      await tester.pumpWidget(SaveEasyApp(deps: AppDependencies.mock(db, storage, images: ImageStorage.forTesting())));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.tap(find.text(label).first);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.byType(label == 'Criar conta' ? SignUpPage : LoginPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
