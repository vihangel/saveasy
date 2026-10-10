import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/data/datasources/image_storage.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/utils/validators.dart';

/// Pedido de verificação (comunidade, empresa, influenciador): nome, CPF/CNPJ
/// e foto do documento (bucket privado).
class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _name = TextEditingController();
  final _doc = TextEditingController();
  final _notes = TextEditingController();
  String? _documentPath;
  bool _sending = false;
  late final Future<({String status, String? reviewNote})> _current = context
      .read<ModerationRepository>()
      .myVerification();

  @override
  void dispose() {
    for (final c in [_name, _doc, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    if (_name.text.trim().length < 3) return context.showMessage('Informe o nome ou a razão social.', error: true);
    final docError = Validators.cpfCnpj(_doc.text);
    if (docError != null) return context.showMessage(docError, error: true);
    if (_documentPath == null) return context.showMessage('Envie a foto do documento.', error: true);
    setState(() => _sending = true);
    try {
      final user = await context.read<ModerationRepository>().requestVerification(
        legalName: _name.text,
        documentNumber: _doc.text,
        documentPath: _documentPath!,
        notes: _notes.text,
      );
      if (!mounted) return;
      context.read<SessionCubit>().updateUser(user);
      context.showMessage('Pedido enviado! A análise leva até 2 dias úteis.');
      context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      context.showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Verificação da conta')),
      body: FutureBuilder(
        future: _current,
        builder: (context, snapshot) {
          final current = snapshot.data;
          if (current == null && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
          final status = current?.status ?? 'unverified';
          if (status == 'verified' || status == 'pending') {
            return EmptyState(
              message: status == 'verified'
                  ? 'Sua conta está verificada. ✔'
                  : 'Seu pedido está em análise. Você recebe uma notificação com o resultado.',
              icon: status == 'verified' ? Icons.verified_rounded : Icons.hourglass_top_rounded,
            );
          }
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Contas verificadas recebem o selo ✔, podem pedir repasses e têm anúncios no ar na hora.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              if (status == 'rejected' && current?.reviewNote != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Motivo da recusa anterior: ${current!.reviewNote}',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nome ou razão social',
                controller: _name,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'CPF ou CNPJ',
                controller: _doc,
                hint: 'Só números',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Observações (opcional)', controller: _notes, maxLines: 3, maxLength: 500),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await showImagePickerSheet(
                    context,
                    title: 'Foto do documento',
                    bucket: ImageBucket.verificationDocs,
                  );
                  if (result is ImagePicked) setState(() => _documentPath = result.reference);
                },
                icon: Icon(_documentPath == null ? Icons.upload_file_rounded : Icons.check_circle_rounded),
                label: Text(_documentPath == null ? 'Enviar foto do documento' : 'Documento enviado'),
              ),
              const SizedBox(height: 8),
              const Text(
                'O documento fica num espaço privado: só você e a equipe de verificação têm acesso.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Enviar para análise', loading: _sending, onPressed: _send),
            ],
          );
        },
      ),
    );
  }
}
