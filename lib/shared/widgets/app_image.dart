import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/datasources/image_storage.dart';

/// Desenha uma imagem salva pelo [ImageStorage] (arquivo local, data URI ou URL).
class AppImage extends StatelessWidget {
  const AppImage({super.key, required this.reference, this.fit = BoxFit.cover, this.width, this.height});

  final String reference;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ImageStorage>().provider(reference);
    if (provider == null) return SizedBox(width: width, height: height);
    return Image(
      image: provider,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => SizedBox(
        width: width,
        height: height,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
