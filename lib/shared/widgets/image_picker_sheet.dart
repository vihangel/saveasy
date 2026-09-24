import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../data/datasources/image_storage.dart';
import '../services/media_picker_service.dart';
import '../utils/context_x.dart';

/// Resultado do fluxo de escolher imagem.
sealed class ImagePickResult {
  const ImagePickResult();
}

class ImagePicked extends ImagePickResult {
  const ImagePicked(this.reference);

  /// Referência já salva localmente, pronta para ir no modelo.
  final String reference;
}

class ImageRemoved extends ImagePickResult {
  const ImageRemoved();
}

/// Fluxo completo: escolher origem → pedir permissão → abrir câmera/galeria →
/// salvar localmente. Retorna null se o usuário cancelar.
Future<ImagePickResult?> showImagePickerSheet(
  BuildContext context, {
  String title = 'Escolher imagem',
  bool canRemove = false,
}) async {
  final choice = await showModalBottomSheet<_Choice>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(context, _Choice.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(context, _Choice.gallery),
          ),
          if (canRemove)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: const Text('Remover imagem', style: TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.pop(context, _Choice.remove),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;
  if (choice == _Choice.remove) return const ImageRemoved();

  final source = choice == _Choice.camera ? ImageSource.camera : ImageSource.gallery;
  final picker = context.read<MediaPickerService>();
  final storage = context.read<ImageStorage>();
  try {
    final file = await picker.pick(source);
    if (file == null) return null;
    return ImagePicked(await storage.save(file));
  } on MediaPermissionException catch (e) {
    if (context.mounted) await _explainPermission(context, e, picker);
  } on CameraUnavailableException {
    if (context.mounted) context.showMessage('Câmera indisponível neste dispositivo. Use a galeria.', error: true);
  } catch (_) {
    if (context.mounted) context.showMessage('Não foi possível carregar a imagem.', error: true);
  }
  return null;
}

enum _Choice { camera, gallery, remove }

Future<void> _explainPermission(BuildContext context, MediaPermissionException e, MediaPickerService picker) async {
  final what = e.source == ImageSource.camera ? 'à câmera' : 'às suas fotos';
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.lock_outline_rounded, color: AppColors.orange),
      title: const Text('Permissão necessária'),
      content: Text(
        e.permanentlyDenied
            ? 'O acesso $what foi bloqueado. Para continuar, libere nas configurações do aparelho.'
            : 'Precisamos de acesso $what para adicionar a imagem.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Agora não')),
        if (e.permanentlyDenied)
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Abrir configurações')),
      ],
    ),
  );
  if (openSettings ?? false) await picker.openSettings();
}
