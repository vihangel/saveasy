import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/view_status.dart';

/// Alterna entre carregando / erro / conteúdo de acordo com o [ViewStatus].
class AsyncBody extends StatelessWidget {
  const AsyncBody({super.key, required this.status, required this.builder, this.error, this.onRetry});

  final ViewStatus status;
  final WidgetBuilder builder;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ViewStatus.initial || ViewStatus.loading => const Center(child: CircularProgressIndicator()),
      ViewStatus.failure => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(error ?? 'Algo deu errado.', textAlign: TextAlign.center),
              if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
            ],
          ),
        ),
      ),
      ViewStatus.success => builder(context),
    };
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_rounded});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // Rolável para não estourar quando sobra pouco espaço (ex.: abas do perfil).
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
