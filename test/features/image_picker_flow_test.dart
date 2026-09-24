import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveeasy2026/app/app.dart';
import 'package:saveeasy2026/shared/data/datasources/image_storage.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/services/media_picker_service.dart';

import '../helpers/test_database.dart';

/// Seletor falso: devolve um arquivo fixo ou simula permissão negada.
class _FakePicker extends MediaPickerService {
  _FakePicker({this.file, this.denied = false});

  final XFile? file;
  final bool denied;
  bool openedSettings = false;

  @override
  Future<XFile?> pick(ImageSource source) async {
    if (denied) throw MediaPermissionException(source: source, permanentlyDenied: true);
    return file;
  }

  @override
  Future<bool> openSettings() async => openedSettings = true;
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('saveeasy_images'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<void> openEditProfile(WidgetTester tester, MediaPickerService picker) async {
    final (db, storage) = await createTestDatabase();
    await storage.writeString('session_user_id', MockSeed.demoUserId);
    await tester.pumpWidget(
      SaveEasyApp(storage: storage, database: db, images: ImageStorage.forTesting(tempDir.path), mediaPicker: picker),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    GoRouter.of(tester.element(find.byType(Navigator).first)).go('/profile/edit');
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('escolher foto da galeria salva localmente e mostra no avatar', (tester) async {
    final source = File('${tempDir.path}/foto.jpg')..writeAsBytesSync(List.filled(16, 0));
    await openEditProfile(tester, _FakePicker(file: XFile(source.path)));

    await tester.tap(find.byIcon(Icons.photo_camera_outlined));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Escolher da galeria'), findsOneWidget);

    await tester.tap(find.text('Escolher da galeria'));
    // A cópia do arquivo é IO real: alterna entre tempo real e frames.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    }

    final saved = Directory('${tempDir.path}/images').listSync();
    expect(saved, hasLength(1), reason: 'a imagem é copiada para a pasta do app');
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('permissão bloqueada mostra explicação e leva às configurações', (tester) async {
    final picker = _FakePicker(denied: true);
    await openEditProfile(tester, picker);

    await tester.tap(find.byIcon(Icons.photo_camera_outlined));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Tirar foto'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Permissão necessária'), findsOneWidget);
    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(picker.openedSettings, isTrue);
  });
}
