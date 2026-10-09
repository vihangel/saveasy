import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';

/// Blocos extras do detalhe: pessoas marcadas, participantes e check-in,
/// atualizações da campanha, fotos de quem participou e doação de itens.
class PostExtrasSection extends StatefulWidget {
  const PostExtrasSection({super.key, required this.post, required this.isAuthor});

  final Post post;
  final bool isAuthor;

  @override
  State<PostExtrasSection> createState() => _PostExtrasSectionState();
}

class _PostExtrasSectionState extends State<PostExtrasSection> {
  PostExtras? _extras;

  EngagementRepository get _repo => context.read<EngagementRepository>();
  Post get _post => widget.post;
  bool get _hasParticipation =>
      const {PostType.event, PostType.socialAction, PostType.activity}.contains(_post.type) && !_isItemGiveaway;
  bool get _isItemGiveaway => _post.type == PostType.activity && _post.activityKind == 'item_giveaway';
  bool get _canAddPhoto => widget.isAuthor || _post.confirmed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PostExtrasSection old) {
    super.didUpdateWidget(old);
    if (old.post.confirmed != _post.confirmed) _load();
  }

  Future<void> _load() async {
    try {
      final extras = await _repo.extras(_post.id);
      if (mounted) setState(() => _extras = extras);
    } on AppException {
      if (mounted) setState(() => _extras = const PostExtras());
    }
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    try {
      await action();
      await _load();
      if (mounted && success != null) context.showMessage(success);
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  Future<void> _addPhoto() async {
    final result = await showImagePickerSheet(context, title: 'Foto da ação');
    if (result is! ImagePicked) return;
    await _run(() => _repo.addPhoto(_post.id, imageUrl: result.reference), success: 'Foto enviada!');
  }

  Future<void> _addUpdate() async {
    final text = await _askText(context, title: 'Nova atualização', hint: 'Conte o que mudou na campanha');
    if (text == null || text.trim().isEmpty) return;
    await _run(
      () => _repo.addUpdate(_post.id, body: text),
      success: 'Atualização publicada e enviada aos interessados.',
    );
  }

  Future<void> _requestItem() async {
    final text = await _askText(context, title: 'Quero receber', hint: 'Conte por que precisa (opcional)');
    if (text == null) return;
    await _run(() => _repo.requestItem(_post.id, message: text), success: 'Pedido enviado!');
  }

  void _showCheckin(String code) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Seu check-in'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 200, height: 200, child: QrImageView(data: 'saveeasy:checkin:${_post.id}:$code')),
          const SizedBox(height: 12),
          SelectableText(code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 4)),
          const SizedBox(height: 8),
          const Text('Mostre este código ao organizador na chegada.', textAlign: TextAlign.center),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final extras = _extras;
    if (extras == null) return const SizedBox.shrink();
    final myRequest = extras.itemRequests.where((r) => r.requester.id == context.currentUser.id).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (extras.mentions.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Com:', style: TextStyle(color: AppColors.textMuted)),
              for (final u in extras.mentions)
                ActionChip(
                  avatar: UserAvatar(name: u.name, imageUrl: u.avatarUrl, size: 20),
                  label: Text('@${u.username}'),
                  onPressed: () => context.push(AppRoutes.user(u.id)),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_hasParticipation) ...[
          _Header(
            title: 'Participantes (${_post.attending})',
            action: _post.attending > 0 || widget.isAuthor ? (widget.isAuthor ? 'Gerenciar' : 'Ver todos') : null,
            onAction: () => context.push(AppRoutes.participants(_post.id)),
          ),
          if (extras.participantsPreview.isNotEmpty)
            SizedBox(
              height: 40,
              child: Stack(
                children: [
                  for (final (i, p) in extras.participantsPreview.indexed)
                    Positioned(
                      left: i * 26.0,
                      child: UserAvatar(name: p.name, imageUrl: p.avatarUrl, size: 36),
                    ),
                ],
              ),
            ),
          if (extras.checkinCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () => _showCheckin(extras.checkinCode!),
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('Meu check-in'),
              ),
            ),
          const SizedBox(height: 16),
        ],
        if (_isItemGiveaway) ...[
          _Header(
            title: 'Doação de itens',
            action: widget.isAuthor ? 'Pedidos (${extras.itemRequests.length})' : null,
            onAction: () async {
              await context.push(AppRoutes.itemRequests(_post.id));
              _load();
            },
          ),
          if (!widget.isAuthor)
            myRequest == null || myRequest.status == ItemRequestStatus.cancelled
                ? FilledButton.icon(
                    onPressed: _requestItem,
                    icon: const Icon(Icons.volunteer_activism_rounded),
                    label: const Text('Quero receber'),
                  )
                : Row(
                    children: [
                      Chip(label: Text('Seu pedido: ${myRequest.status.label}')),
                      const Spacer(),
                      if (myRequest.status == ItemRequestStatus.requested)
                        TextButton(
                          onPressed: () => _run(
                            () => _repo.updateItemRequest(myRequest.id, ItemRequestStatus.cancelled),
                            success: 'Pedido cancelado.',
                          ),
                          child: const Text('Cancelar'),
                        ),
                    ],
                  ),
          const SizedBox(height: 16),
        ],
        if (extras.updates.isNotEmpty || widget.isAuthor) ...[
          _Header(title: 'Atualizações', action: widget.isAuthor ? 'Publicar' : null, onAction: _addUpdate),
          if (extras.updates.isEmpty)
            const Text('Conte as novidades para quem apoia.', style: TextStyle(color: AppColors.textMuted)),
          for (final u in extras.updates)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.relative(u.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(u.body),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
        if (extras.photos.isNotEmpty || (_canAddPhoto && _hasParticipation)) ...[
          _Header(title: 'Fotos de quem participou', action: _canAddPhoto ? 'Adicionar' : null, onAction: _addPhoto),
          if (extras.photos.isEmpty)
            const Text('Ninguém enviou fotos ainda.', style: TextStyle(color: AppColors.textMuted)),
          if (extras.photos.isNotEmpty)
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: extras.photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final photo = extras.photos[i];
                  final mine = photo.authorId == context.currentUser.id;
                  return GestureDetector(
                    onLongPress: mine || widget.isAuthor
                        ? () => _run(() => _repo.deletePhoto(photo.id), success: 'Foto removida.')
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppImage(reference: photo.imageUrl, width: 110, height: 110),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

/// Caixa de texto simples em diálogo. `null` = cancelou.
Future<String?> _askText(BuildContext context, {required String title, required String hint}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        maxLength: 500,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Enviar')),
      ],
    ),
  );
}
