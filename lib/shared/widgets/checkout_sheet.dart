import 'adaptive_sheet.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../notifiers/session_cubit.dart';
import '../utils/formatters.dart';
import 'primary_button.dart';

/// Pagamento com Pix. Cria a cobrança (o valor vem do servidor), mostra o QR
/// e o "copia e cola" e espera a confirmação. No ambiente de testes (sandbox)
/// dá para simular o pagamento. Retorna o usuário atualizado se pagou.
Future<AppUser?> showCheckout(BuildContext context, PaymentIntent intent) {
  return showAdaptiveSheet<AppUser>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CheckoutSheet(intent: intent),
  );
}

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet({required this.intent});

  final PaymentIntent intent;

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  Payment? _payment;
  String? _error;
  bool _confirming = false;
  Timer? _poll;

  WalletRepository get _wallet => context.read<WalletRepository>();

  @override
  void initState() {
    super.initState();
    _create();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _error = null);
    try {
      final payment = await _wallet.createPayment(widget.intent);
      if (!mounted) return;
      setState(() => _payment = payment);
      // Produção: o gateway confirma pelo webhook; o app só acompanha.
      if (!payment.sandbox) _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _check() async {
    final payment = _payment;
    if (payment == null) return;
    try {
      final status = await _wallet.paymentStatus(payment.id);
      if (status.status == PaymentStatus.paid && mounted) {
        _poll?.cancel();
        final user = await context.read<SessionCubit>().refreshUser();
        if (mounted) Navigator.pop(context, user);
      }
    } on AppException {
      // Tenta de novo no próximo ciclo.
    }
  }

  Future<void> _simulate() async {
    setState(() => _confirming = true);
    try {
      final (_, user) = await _wallet.confirmSandboxPayment(_payment!.id, userId: context.read<SessionCubit>().user.id);
      if (!mounted) return;
      context.read<SessionCubit>().updateUser(user);
      Navigator.pop(context, user);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = _payment;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: _error != null && payment == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _create, child: const Text('Tentar de novo')),
                ],
              )
            : payment == null
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Pagar com Pix', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      payment.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.currency(payment.amount),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    if (payment.pixCode != null) ...[
                      SizedBox(width: 180, height: 180, child: QrImageView(data: payment.pixCode!)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: payment.pixCode!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Código Pix copiado!')));
                          }
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copiar código Pix'),
                      ),
                    ],
                    if (payment.expiresAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Válido até ${Formatters.shortDateTime(payment.expiresAt!.toLocal())}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    const SizedBox(height: 20),
                    if (payment.sandbox) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Ambiente de testes: nenhum dinheiro real é cobrado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(label: 'Simular pagamento aprovado', loading: _confirming, onPressed: _simulate),
                    ] else
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Aguardando o pagamento...'),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
