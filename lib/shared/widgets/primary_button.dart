import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Text(label);
    final style = color == null ? null : FilledButton.styleFrom(backgroundColor: color);
    if (icon != null && !loading) {
      return FilledButton.icon(onPressed: onPressed, style: style, icon: Icon(icon), label: child);
    }
    return FilledButton(onPressed: loading ? null : onPressed, style: style, child: child);
  }
}
