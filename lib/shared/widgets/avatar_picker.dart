import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'image_picker_sheet.dart';
import 'user_avatar.dart';

/// Avatar com botão de câmera que abre o fluxo de escolher foto.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key, required this.name, required this.imageUrl, required this.onChanged, this.size = 150});

  final String name;
  final String? imageUrl;

  /// Recebe a nova referência, ou null quando a foto é removida.
  final ValueChanged<String?> onChanged;
  final double size;

  Future<void> _pick(BuildContext context) async {
    final result = await showImagePickerSheet(context, title: 'Foto de perfil', canRemove: imageUrl != null);
    switch (result) {
      case ImagePicked(:final reference):
        onChanged(reference);
      case ImageRemoved():
        onChanged(null);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Alterar foto de perfil',
      child: GestureDetector(
        onTap: () => _pick(context),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: UserAvatar(name: name.isEmpty ? ' ' : name, imageUrl: imageUrl, size: size),
            ),
            Positioned(
              right: size * 0.02,
              bottom: size * 0.02,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.photo_camera_outlined, color: Colors.white),
                onPressed: () => _pick(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
