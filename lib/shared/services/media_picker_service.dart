import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permissão de câmera/galeria negada pelo usuário.
class MediaPermissionException implements Exception {
  const MediaPermissionException({required this.source, required this.permanentlyDenied});

  final ImageSource source;

  /// Quando true, o sistema não mostra mais o pedido: só pelas configurações.
  final bool permanentlyDenied;
}

/// A câmera não está disponível (ex.: simulador de iOS).
class CameraUnavailableException implements Exception {
  const CameraUnavailableException();
}

/// Pede a permissão necessária e abre a câmera ou a galeria.
///
/// - Câmera: exige `Permission.camera` (iOS e Android).
/// - Galeria no iOS: `Permission.photos` (acesso limitado também é aceito).
/// - Galeria no Android: o Photo Picker do sistema não precisa de permissão.
/// - Web: o navegador cuida das permissões.
class MediaPickerService {
  MediaPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pick(ImageSource source) async {
    await _ensurePermission(source);
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );
    } on PlatformException catch (e) {
      if (e.code == 'no_available_camera') throw const CameraUnavailableException();
      if (e.code.contains('access_denied')) {
        throw MediaPermissionException(source: source, permanentlyDenied: true);
      }
      rethrow;
    }
  }

  Future<bool> openSettings() => openAppSettings();

  Future<void> _ensurePermission(ImageSource source) async {
    final permission = _permissionFor(source);
    if (permission == null) return;
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return;
    if (!status.isPermanentlyDenied) status = await permission.request();
    if (status.isGranted || status.isLimited) return;
    throw MediaPermissionException(
      source: source,
      permanentlyDenied: status.isPermanentlyDenied || status.isRestricted,
    );
  }

  Permission? _permissionFor(ImageSource source) {
    if (kIsWeb) return null;
    return switch ((source, defaultTargetPlatform)) {
      (ImageSource.camera, TargetPlatform.iOS || TargetPlatform.android) => Permission.camera,
      (ImageSource.gallery, TargetPlatform.iOS) => Permission.photos,
      _ => null,
    };
  }
}
