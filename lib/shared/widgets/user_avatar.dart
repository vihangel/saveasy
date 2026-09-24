import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'app_image.dart';

/// Avatar com iniciais (os dados mockados não têm fotos).
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.imageUrl, this.size = 40, this.ring = false});

  final String name;

  /// Foto do usuário; sem ela mostra as iniciais.
  final String? imageUrl;
  final double size;

  /// Anel laranja usado nos stories não vistos.
  final bool ring;

  static const _palette = [
    Color(0xFF6176ED),
    Color(0xFFFA7E2A),
    Color(0xFF2EB67D),
    Color(0xFFE5484D),
    Color(0xFF8E5CD9),
    Color(0xFF16A2B8),
  ];

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length > 1 ? parts.first[0] + parts.last[0] : (name.isEmpty ? '?' : name[0]);
    final color = _palette[name.hashCode.abs() % _palette.length];
    final Widget avatar = imageUrl != null
        ? ClipOval(
            child: AppImage(reference: imageUrl!, width: size, height: size),
          )
        : CircleAvatar(
            radius: size / 2,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              initials.toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: size * 0.36),
            ),
          );
    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.orange, AppColors.primary]),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: avatar,
      ),
    );
  }
}
