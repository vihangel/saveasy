import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/widgets/widgets.dart';

/// Convide amigos: código próprio, números e campo para usar o código de
/// quem convidou (primeiros 30 dias).
class InvitePage extends StatefulWidget {
  const InvitePage({super.key});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  InviteInfo? _info;
  String? _error;
  bool _redeeming = false;
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final info = await context.read<GamificationRepository>().invite();
      if (mounted) setState(() => _info = info);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _redeem() async {
    if (_code.text.trim().isEmpty) return;
    setState(() => _redeeming = true);
    try {
      final user = await context.read<GamificationRepository>().redeemInvite(
        _code.text,
        userId: context.currentUser.id,
      );
      if (!mounted) return;
      context.read<SessionCubit>().updateUser(user);
      context.showMessage('Código aceito! +100 moedas');
      await _load();
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return AppPage(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Convide amigos')),
      body: _error != null
          ? EmptyState(message: _error!, icon: Icons.cloud_off)
          : info == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.group_add_rounded, size: 64, color: AppColors.orange),
                const SizedBox(height: 12),
                Text(
                  'Ganhe moedas trazendo amigos para fazer o bem',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Seu amigo ganha 100 moedas ao usar seu código. Você ganha 50 na hora e mais '
                  '1.000 quando ele chegar ao nível 20.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          info.code.toUpperCase(),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 3),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Copiar convite',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text:
                                  'Vem fazer o bem comigo no Save Easy! Use meu código ${info.code.toUpperCase()} '
                                  'e ganhe 100 moedas: https://vihangel.github.io/saveasy/',
                            ),
                          );
                          if (context.mounted) context.showMessage('Convite copiado!');
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Number(value: info.invited, label: 'amigos entraram'),
                    _Number(value: info.reachedLevel20, label: 'chegaram ao nível 20'),
                  ],
                ),
                if (info.invitedBy != null) ...[
                  const SizedBox(height: 24),
                  ListTile(
                    leading: UserAvatar(name: info.invitedBy!.name, imageUrl: info.invitedBy!.avatarUrl, size: 40),
                    title: Text('Você foi convidado por ${info.invitedBy!.name}'),
                  ),
                ],
                if (info.canRedeem) ...[
                  const SizedBox(height: 24),
                  Text('Recebeu um código?', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'Código do seu amigo'),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Usar código', loading: _redeeming, onPressed: _redeem),
                ],
              ],
            ),
    );
  }
}

class _Number extends StatelessWidget {
  const _Number({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.headlineSmall),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
