import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/widgets/widgets.dart';

/// Publicações salvas / "Tenho interesse".
class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  late Future<List<Post>> _posts = context.read<PostRepository>().saved();

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Salvos e interesses')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _posts = context.read<PostRepository>().saved());
          await _posts;
        },
        child: FutureBuilder<List<Post>>(
          future: _posts,
          builder: (context, snapshot) {
            final posts = snapshot.data;
            if (snapshot.hasError) {
              return ListView(
                children: [EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off)],
              );
            }
            if (posts == null) return const Center(child: CircularProgressIndicator());
            if (posts.isEmpty) {
              return ListView(
                children: const [
                  EmptyState(
                    message: 'Toque no marcador ou em "Tenho interesse" para guardar publicações aqui.',
                    icon: Icons.bookmark_border_rounded,
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, i) => PostCard(post: posts[i], commentsCount: posts[i].commentsCount),
            );
          },
        ),
      ),
    );
  }
}
