import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/widgets/widgets.dart';

/// "Stories - Add". Formulário simples, sem cubit próprio: o estado é só
/// local da tela e a publicação vai direto para o repositório.
class NewStoryPage extends StatefulWidget {
  const NewStoryPage({super.key});

  @override
  State<NewStoryPage> createState() => _NewStoryPageState();
}

class _NewStoryPageState extends State<NewStoryPage> {
  final _text = TextEditingController();
  PostType _type = PostType.socialAction;
  String? _image;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await showImagePickerSheet(context, title: 'Imagem do story', canRemove: _image != null);
    switch (result) {
      case ImagePicked(:final reference):
        setState(() => _image = reference);
      case ImageRemoved():
        setState(() => _image = null);
      case null:
        break;
    }
  }

  Future<void> _publish() async {
    if (_text.text.trim().isEmpty && _image == null) {
      return context.showMessage('Escreva algo ou adicione uma imagem.', error: true);
    }
    setState(() => _saving = true);
    final user = await context.read<StoryRepository>().create(
      author: context.currentUser,
      type: _type,
      text: _text.text,
      imageUrl: _image,
    );
    if (!mounted) return;
    context.read<SessionCubit>().updateUser(user);
    context.showMessage('Story publicado! +20 moedas');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = PostCover.colorsFor(_type);
    return Scaffold(
      backgroundColor: colors.last,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Novo story', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Adicionar imagem',
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _pickImage,
          ),
        ],
      ),
      extendBodyBehindAppBar: _image != null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_image != null) ...[
            AppImage(reference: _image!),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x22000000), Color(0x99000000)],
                ),
              ),
            ),
          ],
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final type in PostType.values.where((t) => t != PostType.ad))
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(type.label),
                              selected: _type == type,
                              onSelected: (_) => setState(() => _type = type),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: TextField(
                        controller: _text,
                        maxLines: null,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                        decoration: const InputDecoration(
                          filled: false,
                          hintText: 'Conte a sua boa ação de hoje...',
                          hintStyle: TextStyle(color: Colors.white70, fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Ao publicar você ganha ', style: TextStyle(color: Colors.white)),
                      CoinChip(coins: 20, prefix: '+', light: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Publicar', loading: _saving, color: AppColors.orange, onPressed: _publish),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
