import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/breakpoints.dart';

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

  /// Uma linha explicando cada tipo (usada nos cartões do desktop).
  static const _descriptions = {
    PostType.donation: 'Arrecade dinheiro por Pix ou moedas para uma causa.',
    PostType.event: 'Divulgue um evento presencial ou online com data e local.',
    PostType.socialAction: 'Mostre uma ação social que você fez ou vai fazer.',
    PostType.tutorial: 'Ensine o passo a passo de algo que ajuda outras pessoas.',
    PostType.ad: 'Anuncie para a região; parte do valor vai para o fundo de doações.',
    PostType.activity: 'Convide voluntários para uma atividade com vagas.',
    PostType.discussion: 'Abra uma conversa com a comunidade.',
  };

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
    final search = TextField(
      onChanged: (v) => setState(() => _query = v),
      decoration: const InputDecoration(
        hintText: 'Pesquisar por outros tipos de publicações',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
    if (!context.isCompact) return _wideLayout(context, types, search);
    return AppPage(
      maxWidth: Breakpoints.content,
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
            child: Padding(padding: const EdgeInsets.all(20), child: search),
          ),
        ],
      ),
    );
  }

  /// Tablet/desktop: busca no topo e cartões com ícone, nome e descrição.
  Widget _wideLayout(BuildContext context, List<PostType> types, Widget search) {
    return AppPage(
      maxWidth: 880,
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Criar uma publicação')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Text('O que você quer publicar?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Escolha um tipo para abrir o formulário certo.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          search,
          const SizedBox(height: 24),
          if (types.isEmpty)
            const EmptyState(message: 'Nenhum tipo encontrado.', icon: Icons.search_off_rounded)
          else
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth >= 640 ? 3 : 2;
                final width = (box.maxWidth - 16 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final type in types)
                      SizedBox(
                        width: width,
                        child: _TypeCard(type: type, description: _descriptions[type] ?? '', onTap: () => _open(type)),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatefulWidget {
  const _TypeCard({required this.type, required this.description, required this.onTap});

  final PostType type;
  final String description;
  final VoidCallback onTap;

  @override
  State<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends State<_TypeCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _hover ? AppColors.primary : AppColors.border),
          boxShadow: _hover ? const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))] : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: ClipOval(child: PostCover(type: widget.type, height: 52, radius: 26, iconSize: 24)),
                  ),
                  const SizedBox(height: 14),
                  Text(widget.type.label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
