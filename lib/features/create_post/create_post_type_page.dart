import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/widgets/widgets.dart';

/// "Criar Publicação": escolha do tipo.
class CreatePostTypePage extends StatefulWidget {
  const CreatePostTypePage({super.key});

  @override
  State<CreatePostTypePage> createState() => _CreatePostTypePageState();
}

class _CreatePostTypePageState extends State<CreatePostTypePage> {
  String _query = '';

  static const _order = [
    PostType.donation,
    PostType.event,
    PostType.socialAction,
    PostType.tutorial,
    PostType.ad,
    PostType.activity,
    PostType.discussion,
  ];

  void _open(PostType type) {
    if (type == PostType.ad) {
      context.push(AppRoutes.adInfo);
    } else {
      context.push(AppRoutes.createForm(type.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = _order.where((t) => t.label.toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Criar uma publicação'), centerTitle: false),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text('Escolha o tipo de publicação:', style: TextStyle(color: AppColors.textDark)),
          ),
          Expanded(
            child: GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 112 + 24 * context.textScale,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              children: [
                for (final type in types)
                  InkWell(
                    onTap: () => _open(type),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 96,
                          child: ClipOval(child: PostCover(type: type, height: 96, radius: 48, iconSize: 40)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Pesquisar por outros tipos de publicações',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
