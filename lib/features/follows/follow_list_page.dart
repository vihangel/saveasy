import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/utils/view_status.dart';
import '../../shared/widgets/widgets.dart';

/// Seguidores / Seguindo de um perfil (lista somente leitura).
class FollowListPage extends StatefulWidget {
  const FollowListPage({super.key, required this.profileId, required this.kind});

  final String profileId;
  final FollowListKind kind;

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  late Future<List<AppUser>> _users = _load();

  Future<List<AppUser>> _load() => context.read<UserRepository>().followList(widget.profileId, widget.kind);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(fallback: AppRoutes.user(widget.profileId)),
        title: Text(widget.kind == FollowListKind.followers ? 'Seguidores' : 'Seguindo'),
      ),
      body: FutureBuilder<List<AppUser>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AsyncBody(
              status: ViewStatus.failure,
              error: snapshot.error.toString(),
              onRetry: () => setState(() => _users = _load()),
              builder: (_) => const SizedBox(),
            );
          }
          final users = snapshot.data;
          if (users == null) return const Center(child: CircularProgressIndicator());
          if (users.isEmpty) {
            return EmptyState(
              message: widget.kind == FollowListKind.followers
                  ? 'Ninguém segue este perfil ainda.'
                  : 'Este perfil ainda não segue ninguém.',
              icon: Icons.people_outline_rounded,
            );
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, i) {
              final user = users[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: UserAvatar(name: user.name, imageUrl: user.avatarUrl, size: 44),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('@${user.username} · ${Formatters.compact(user.followers)} seguidores'),
                onTap: () => context.push(AppRoutes.user(user.id)),
              );
            },
          );
        },
      ),
    );
  }
}
