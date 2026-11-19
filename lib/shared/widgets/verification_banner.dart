import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../data/models/models.dart';
import '../notifiers/session_cubit.dart';

/// Convite para verificar a conta (empresa, comunidade e influenciador).
///
/// Some para contas pessoais e para quem já está verificado; em análise,
/// mostra só o aviso de espera.
class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key, this.message, this.margin = EdgeInsets.zero});

  /// Texto principal; o padrão explica o que a verificação libera.
  final String? message;
  final EdgeInsets margin;

  static bool needsVerification(AppUser? user) =>
      user != null && user.accountType != AccountType.personal && user.verificationStatus != 'verified';

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.userOrNull);
    if (!needsVerification(user)) return const SizedBox.shrink();
    final pending = user!.verificationStatus == 'pending';
    return Padding(
      padding: margin,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD9BF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(pending ? Icons.hourglass_top_rounded : Icons.verified_outlined, color: AppColors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pending ? 'Verificação em análise' : 'Verifique sua conta',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pending
                        ? 'Você recebe uma notificação com o resultado em até 2 dias úteis.'
                        : message ??
                              'Contas verificadas recebem o selo ✔, podem pedir repasses e têm anúncios no ar na hora.',
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.text),
                  ),
                  if (!pending) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => context.push(AppRoutes.verification),
                      child: const Text('Verificar agora →'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
