import 'package:flutter/material.dart';

import '../../app/breakpoints.dart';

class AdaptiveCards extends StatelessWidget {
  const AdaptiveCards({super.key, required this.children, this.minWidth = 260});
  final List<Widget> children;
  final double minWidth;
  @override
  Widget build(BuildContext context) {
    if (context.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 16), children[i]],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final columns = (box.maxWidth / minWidth).floor().clamp(1, 3);
        final width = (box.maxWidth - 16 * (columns - 1)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      },
    );
  }
}
