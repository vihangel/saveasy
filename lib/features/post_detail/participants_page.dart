import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/widgets/widgets.dart';
import 'qr_scan_page.dart';

/// Lista de participantes. O organizador marca presença por pessoa ou pelo
/// código que o participante mostra (QR/texto).
class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({super.key, required this.postId});

  final String postId;

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  List<Participant>? _items;
  Post? _post;
  String? _error;
  final _code = TextEditingController();

  bool get _isAuthor => _post?.authorId == context.currentUser.id;

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
      final (post, items) = await (
        context.read<PostRepository>().getById(widget.postId),
        context.read<EngagementRepository>().participants(widget.postId),
      ).wait;
      if (!mounted) return;
      setState(() {
        _post = post;
        _items = items;
      });
    } on ParallelWaitError {
      if (mounted) setState(() => _error = 'Não foi possível carregar os participantes.');
    }
  }

  Future<void> _checkIn({String? profileId, String? code, bool attended = true}) async {
    try {
      final items = await context.read<EngagementRepository>().checkIn(
        widget.postId,
        profileId: profileId,
        code: code,
        attended: attended,
      );
      if (!mounted) return;
      setState(() => _items = items);
      _code.clear();
      context.showMessage(attended ? 'Presença confirmada (+10 XP para a pessoa).' : 'Marcado como falta.');
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final present = items?.where((p) => p.status == ParticipationStatus.attended).length ?? 0;
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Participantes')),
      body: _error != null
          ? EmptyState(message: _error!, icon: Icons.cloud_off)
          : items == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                if (_isAuthor) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Text(
                      '$present de ${items.length} presentes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _code,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Código de check-in',
                              prefixIcon: Icon(Icons.qr_code_2_rounded),
                            ),
                            onSubmitted: (v) => _checkIn(code: v),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Confirmar código',
                          onPressed: () => _checkIn(code: _code.text),
                          icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                        ),
                        IconButton(
                          tooltip: 'Ler QR com a câmera',
                          onPressed: () async {
                            final code = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(builder: (_) => const QrScanPage()),
                            );
                            if (code != null) await _checkIn(code: code);
                          },
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
                if (items.isEmpty)
                  const EmptyState(message: 'Ninguém confirmou presença ainda.', icon: Icons.groups_outlined),
                for (final p in items)
                  ListTile(
                    leading: UserAvatar(name: p.user.name, imageUrl: p.user.avatarUrl, size: 40),
                    title: Text(p.user.name),
                    subtitle: Text('@${p.user.username} · ${p.status.label}'),
                    onTap: () => context.push(AppRoutes.user(p.user.id)),
                    trailing: !_isAuthor
                        ? null
                        : PopupMenuButton<bool>(
                            tooltip: 'Presença',
                            icon: Icon(
                              p.status == ParticipationStatus.attended
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: p.status == ParticipationStatus.attended ? AppColors.success : AppColors.textMuted,
                            ),
                            onSelected: (attended) => _checkIn(profileId: p.user.id, attended: attended),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: true, child: Text('Presente')),
                              PopupMenuItem(value: false, child: Text('Faltou')),
                            ],
                          ),
                  ),
              ],
            ),
    );
  }
}
