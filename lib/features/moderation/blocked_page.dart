import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/widgets/widgets.dart';

/// Perfis bloqueados, com opção de desbloquear.
class BlockedPage extends StatefulWidget {
  const BlockedPage({super.key});

  @override
  State<BlockedPage> createState() => _BlockedPageState();
}

class _BlockedPageState extends State<BlockedPage> {
  late Future<List<AppUser>> _blocked = context.read<ModerationRepository>().blocked();

  Future<void> _unblock(AppUser user) async {
    try {
      await context.read<ModerationRepository>().toggleBlock(user.id);
      if (!mounted) return;
      setState(() => _blocked = context.read<ModerationRepository>().blocked());
      context.showMessage('${user.name} desbloqueado.');
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Perfis bloqueados')),
      body: FutureBuilder<List<AppUser>>(
        future: _blocked,
        builder: (context, snapshot) {
          final users = snapshot.data;
          if (snapshot.hasError) return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
          if (users == null) return const Center(child: CircularProgressIndicator());
          if (users.isEmpty) return const EmptyState(message: 'Você não bloqueou ninguém.', icon: Icons.block_rounded);
          return ListView(
            children: [
              for (final u in users)
                ListTile(
                  leading: UserAvatar(name: u.name, imageUrl: u.avatarUrl, size: 40),
                  title: Text(u.name),
                  subtitle: Text('@${u.username}'),
                  trailing: TextButton(onPressed: () => _unblock(u), child: const Text('Desbloquear')),
                ),
            ],
          );
        },
      ),
    );
  }
}
