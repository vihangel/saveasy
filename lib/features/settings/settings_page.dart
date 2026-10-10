import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/links.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/widgets.dart';

/// Configurações: conta, senha, termos, sair e excluir conta (LGPD).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final password = await showDialog<String>(context: context, builder: (_) => const _ChangePasswordDialog());
    if (password == null || !context.mounted) return;
    try {
      await context.read<AuthRepository>().changePassword(password);
      if (context.mounted) context.showMessage('Senha alterada.');
    } on AppException catch (e) {
      if (context.mounted) context.showMessage(e.message, error: true);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (_) => const _DeleteAccountDialog());
    if (!(confirmed ?? false) || !context.mounted) return;
    try {
      await context.read<SessionCubit>().deleteAccount();
    } on AppException catch (e) {
      if (context.mounted) context.showMessage(e.message, error: true);
    }
  }

  void _showText(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleLarge),
              const SizedBox(height: 12),
              Text(body, style: const TextStyle(height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.userOrNull);
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            leading: UserAvatar(name: user.name, imageUrl: user.avatarUrl, size: 48),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(user.email.isEmpty ? '@${user.username}' : user.email),
          ),
          const _Section('Conta'),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Editar perfil'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded),
            title: const Text('Alterar senha'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _changePassword(context),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border_rounded),
            title: const Text('Salvos e interesses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.saved),
          ),
          if (user.accountType.name != 'personal')
            ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: const Text('Verificação da conta'),
              subtitle: Text(switch (user.verificationStatus) {
                'verified' => 'Verificada',
                'pending' => 'Em análise',
                'rejected' => 'Recusada. Toque para enviar de novo',
                _ => 'Não verificada. Necessária para repasses e anúncios imediatos',
              }),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.verification),
            ),
          if (user.accountType.name == 'community')
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Planos de inscrição'),
              subtitle: const Text('Preços e benefícios para apoiadores'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.plans),
            ),
          ListTile(
            leading: const Icon(Icons.block_rounded),
            title: const Text('Perfis bloqueados'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.blocked),
          ),
          if (user.isStaff)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
              title: const Text('Painel da equipe'),
              subtitle: const Text('Moderação, verificações, anúncios e repasses'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.admin),
            ),
          const _Section('Sobre'),
          ListTile(
            leading: const Icon(Icons.account_balance_rounded),
            title: const Text('Transparência'),
            subtitle: const Text('Fundo de doações e números da plataforma'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.transparency),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Termos de uso'),
            onTap: () => _showText(
              context,
              'Termos de uso',
              'Rascunho. O texto definitivo está em elaboração com o jurídico e será publicado antes do lançamento.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de privacidade'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => openExternalLink('https://vihangel.github.io/saveasy/privacidade.html'),
          ),
          const _Section(''),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sair'),
            onTap: () => context.read<SessionCubit>().logout(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
            title: const Text('Excluir conta', style: TextStyle(color: AppColors.danger)),
            subtitle: const Text('Apaga perfil, publicações e histórico. Não dá para desfazer.'),
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: title.isEmpty
          ? const Divider()
          : Text(
              title,
              style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar senha'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Nova senha',
              controller: _password,
              obscure: true,
              hint: 'Letras e números, 8+ caracteres',
              validator: Validators.password,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Repita a nova senha',
              obscure: true,
              validator: Validators.confirmPassword(() => _password.text),
              autofillHints: const [AutofillHints.newPassword],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            if (_form.currentState!.validate()) Navigator.pop(context, _password.text);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Pede para digitar EXCLUIR antes de apagar a conta.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  String _typed = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Excluir sua conta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seu perfil, publicações, comentários, moedas e histórico serão apagados.'),
          const SizedBox(height: 12),
          const Text('Digite EXCLUIR para confirmar:'),
          const SizedBox(height: 8),
          TextField(onChanged: (v) => setState(() => _typed = v)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(
          onPressed: _typed.trim().toUpperCase() == 'EXCLUIR' ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Excluir conta'),
        ),
      ],
    );
  }
}
