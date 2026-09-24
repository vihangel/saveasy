import 'package:flutter/material.dart';

import '../data/models/models.dart';
import '../utils/app_icons.dart';
import 'app_image.dart';

/// Capa ilustrativa gerada a partir do tipo da publicação
/// (substitui as fotos do protótipo enquanto não há upload real).
class PostCover extends StatelessWidget {
  const PostCover({super.key, required this.type, this.imageUrl, this.height = 160, this.radius = 16, this.iconSize});

  final PostType type;

  /// Imagem enviada pelo autor. Sem ela, mostra a capa gerada pelo tipo.
  final String? imageUrl;
  final double height;
  final double radius;
  final double? iconSize;

  static List<Color> colorsFor(PostType type) => switch (type) {
    PostType.donation => const [Color(0xFFFFA16C), Color(0xFFFA7E2A)],
    PostType.event => const [Color(0xFF8A9BFF), Color(0xFF6176ED)],
    PostType.socialAction => const [Color(0xFF6ED3A6), Color(0xFF2EB67D)],
    PostType.activity => const [Color(0xFF7FD6E5), Color(0xFF16A2B8)],
    PostType.tutorial => const [Color(0xFFC3A4F5), Color(0xFF8E5CD9)],
    PostType.discussion => const [Color(0xFFFFD27A), Color(0xFFF2A516)],
    PostType.ad => const [Color(0xFFFF8F95), Color(0xFFE5484D)],
  };

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: AppImage(reference: imageUrl!, height: height, width: double.infinity),
      );
    }
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(colors: colorsFor(type), begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(AppIcons.postType(type), size: height * 0.9, color: Colors.white.withValues(alpha: 0.18)),
          ),
          Center(
            child: Icon(AppIcons.postType(type), size: iconSize ?? height * 0.35, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
