import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';

/// Pedidos recebidos numa doação de itens (visão de quem doa).
class ItemRequestsPage extends StatefulWidget {
  const ItemRequestsPage({super.key, required this.postId});

  final String postId;

  @override
  State<ItemRequestsPage> createState() => _ItemRequestsPageState();
}

class _ItemRequestsPageState extends State<ItemRequestsPage> {
  List<ItemRequest>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await context.read<EngagementRepository>().itemRequests(widget.postId);
      if (mounted) setState(() => _items = items);
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  Future<void> _update(ItemRequest request, ItemRequestStatus status) async {
    try {
      await context.read<EngagementRepository>().updateItemRequest(request.id, status);
      await _load();
      if (mounted && status == ItemRequestStatus.delivered) {
        context.showMessage('Entrega registrada! Recompensa creditada.');
      }
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Pedidos do item')),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const EmptyState(message: 'Ninguém pediu esse item ainda.', icon: Icons.volunteer_activism_outlined)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = items[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.user(r.requester.id)),
                            child: UserAvatar(name: r.requester.name, imageUrl: r.requester.avatarUrl, size: 40),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.requester.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  '${r.status.label} · ${Formatters.relative(r.createdAt)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (r.message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(r.message)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (r.status == ItemRequestStatus.requested) ...[
                            FilledButton(
                              onPressed: () => _update(r, ItemRequestStatus.accepted),
                              child: const Text('Aceitar'),
                            ),
                            OutlinedButton(
                              onPressed: () => _update(r, ItemRequestStatus.rejected),
                              child: const Text('Recusar'),
                            ),
                          ],
                          if (r.status == ItemRequestStatus.accepted)
                            FilledButton.icon(
                              onPressed: () => _update(r, ItemRequestStatus.delivered),
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Marcar entregue'),
                            ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final thread = await context.read<ChatRepository>().openWith(r.requester);
                                if (context.mounted) context.push(AppRoutes.chat(thread.id));
                              } on AppException catch (e) {
                                if (context.mounted) context.showMessage(e.message, error: true);
                              }
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            label: const Text('Conversar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
