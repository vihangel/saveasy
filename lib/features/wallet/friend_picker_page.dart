import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';

/// Interpretação do frame "iPhone X, XS, 11 Pro – 27" (busca + contatos +
/// saldo): escolher para quem enviar moedas.
class FriendPickerPage extends StatefulWidget {
  const FriendPickerPage({super.key});

  @override
  State<FriendPickerPage> createState() => _FriendPickerPageState();
}

class _FriendPickerPageState extends State<FriendPickerPage> {
  late Future<List<AppUser>> _users = _search('');

  Future<List<AppUser>> _search(String q) =>
      context.read<UserRepository>().search(q, excludeId: context.currentUser.id);

  @override
  Widget build(BuildContext context) {
    final coins = context.select((SessionCubit c) => c.state.userOrNull?.coins ?? 0);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.wallet),
        title: const Text('Enviar moedas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Seu saldo:', style: TextStyle(color: AppColors.textMuted)),
                CoinChip(coins: coins),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (q) => setState(() => _users = _search(q)),
              decoration: const InputDecoration(hintText: 'Buscar pessoas', prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AppUser>>(
              future: _users,
              builder: (context, snapshot) {
                final users = snapshot.data;
                if (users == null) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: UserAvatar(name: user.name, imageUrl: user.avatarUrl, size: 44),
                      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('@${user.username} · ${Formatters.compact(user.followers)} seguidores'),
                      trailing: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                        onPressed: () => context.push(AppRoutes.sendCoins(user.id)),
                        child: const Text('Enviar'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
