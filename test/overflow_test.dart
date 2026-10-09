import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saveeasy2026/app/app.dart';
import 'package:saveeasy2026/app/dependencies.dart';
import 'package:saveeasy2026/shared/data/datasources/image_storage.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/data/models/models.dart';

import 'helpers/test_database.dart';

/// Abre cada rota em telas pequenas e com fonte aumentada e falha se algum
/// widget estourar o espaço (os avisos amarelo/preto de overflow).
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const loggedRoutes = [
    '/home',
    '/messages',
    '/notifications',
    '/profile',
    '/profile/edit',
    '/settings',
    '/saved',
    '/users/u_elefantes/follows',
    '/users/u_me/follows?kind=following',
    '/post/p_escola/edit',
    '/create',
    '/create/ad-info',
    '/create/donation',
    '/create/event',
    '/create/socialAction',
    '/create/activity',
    '/create/tutorial',
    '/create/discussion',
    '/create/ad',
    '/post/p_escola',
    '/post/p_oxigenio',
    '/post/p_live',
    '/post/p_sangue',
    '/post/p_lixao',
    '/post/p_sopao',
    '/post/p_reciclagem',
    '/post/p_tutorial',
    '/post/p_discussao',
    '/post/p_ad',
    '/post/p_escola/donate',
    '/post/p_live/confirmed',
    '/stories/0',
    '/stories/3',
    '/stories/new',
    '/users/u_whinderson',
    '/users/u_elefantes',
    '/users/u_bandeirantes',
    '/users/u_elefantes/subscribe',
    '/users/u_whinderson/send-coins?post=p_oxigenio',
    '/messages/ch_whinderson',
    '/messages/ch_elefantes',
    '/wallet',
    '/wallet/send',
    '/rewards',
    '/rewards/r_cover_dj',
    '/rewards/r_badge_vegan',
    '/achievements',
    '/store',
    '/store/pr_portacopo',
    '/invite',
    '/users/u_me/activity',
    '/post/p_sangue/participants',
    '/post/p_reciclagem/requests',
    '/orders',
    '/finance',
    '/store/manage',
    '/store/manage/new',
    '/ads',
    '/ads/new',
    '/settings/verification',
    '/settings/blocked',
    '/admin',
    '/transparencia',
  ];

  const publicRoutes = ['/welcome', '/login', '/forgot-password', '/signup', '/signup/verify'];

  const sizes = {
    'iPhone SE (320x568)': Size(320, 568),
    'Android pequeno (360x640)': Size(360, 640),
    'Desktop (1280x800)': Size(1280, 800),
  };
  const textScales = [1.0, 1.3];

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final scale in textScales) {
      testWidgets('sem overflow · $sizeName · fonte ${scale}x', timeout: const Timeout(Duration(minutes: 3)), (
        tester,
      ) async {
        final overflows = <String>[];
        final previous = FlutterError.onError;
        String current = '';
        FlutterError.onError = (details) {
          // Registra overflows e qualquer outro erro de layout/renderização.
          final where = RegExp(r'file:///\S+/lib/(\S+:\d+)').firstMatch(details.toString())?.group(1) ?? '?';
          overflows.add('$current → $where → ${details.exceptionAsString().split('\n').first}');
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final (db, storage) = await createTestDatabase();
        await tester.pumpWidget(
          SaveEasyApp(deps: AppDependencies.mock(db, storage, images: ImageStorage.forTesting())),
        );
        await _settle(tester);

        Future<void> visit(String route) async {
          current = route;
          debugPrint('VISITANDO $route');
          GoRouter.of(tester.element(find.byType(Navigator).first)).go(route);
          await _settle(tester);
          await _scrollEverything(tester);
        }

        // Deslogado (onboarding já visto).
        await storage.writeBool('onboarding_seen', true);
        for (final route in publicRoutes) {
          await visit(route);
        }

        // Logado, mas com o perfil ainda incompleto (onboarding).
        db.users = [
          ...db.users,
          const AppUser(
            id: 'u_novo',
            name: 'Pessoa Nova',
            username: 'user_novo',
            email: 'novo@teste.com',
            accountType: AccountType.personal,
            onboardingCompleted: false,
          ),
        ];
        await storage.writeString('session_user_id', 'u_novo');
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          SaveEasyApp(deps: AppDependencies.mock(db, storage, images: ImageStorage.forTesting())),
        );
        await _settle(tester);
        for (final route in ['/onboarding', '/onboarding/profile', '/onboarding/address']) {
          await visit(route);
        }

        // Logado com a conta demo.
        await storage.writeString('session_user_id', MockSeed.demoUserId);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          SaveEasyApp(deps: AppDependencies.mock(db, storage, images: ImageStorage.forTesting())),
        );
        await _settle(tester);
        for (final route in loggedRoutes) {
          await visit(route);
        }

        // Desmonta o app para não deixar timers pendentes.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));

        FlutterError.onError = previous;
        final problems = overflows.toSet().toList();
        for (final p in problems) {
          debugPrint('PROBLEMA: $p');
        }
        expect(problems, isEmpty);
      });
    }
  }
}

/// Deixa passar a splash, a latência mockada e as animações (sem esperar os
/// indicadores de progresso infinitos).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Rola as listas para que os itens fora da tela também sejam desenhados.
Future<void> _scrollEverything(WidgetTester tester) async {
  final scrollables = find.byType(Scrollable).hitTestable();
  for (var i = 0; i < 4; i++) {
    if (scrollables.evaluate().isEmpty) return;
    await tester.drag(scrollables.first, const Offset(0, -400), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
  }
}
