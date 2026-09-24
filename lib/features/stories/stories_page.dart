import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/datasources/image_storage.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'stories_cubit.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  static Widget route(BuildContext context, int index) => BlocProvider(
    create: (context) => StoriesCubit(context.read<StoryRepository>(), context.read<SessionCubit>(), index)..load(),
    child: const StoriesPage(),
  );

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> with SingleTickerProviderStateMixin {
  late final _progress = AnimationController(vsync: this, duration: const Duration(seconds: 5))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) context.read<StoriesCubit>().next();
    });

  /// Volta para a tela anterior ou para o início quando o story foi aberto por link direto.
  void _close(BuildContext context) => context.canPop() ? context.pop() : context.go(AppRoutes.home);

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoriesCubit, StoriesState>(
      listenWhen: (a, b) => a.index != b.index || a.finished != b.finished || a.status != b.status,
      listener: (context, state) {
        if (state.finished) return _close(context);
        _progress.forward(from: 0);
      },
      builder: (context, state) {
        if (state.stories.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final story = state.stories[state.index];
        final colors = PostCover.colorsFor(story.type);
        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTapUp: (details) {
              final width = MediaQuery.sizeOf(context).width;
              final cubit = context.read<StoriesCubit>();
              details.localPosition.dx < width / 3 ? cubit.previous() : cubit.next();
            },
            onLongPressStart: (_) => _progress.stop(),
            onLongPressEnd: (_) => _progress.forward(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                image: story.imageUrl == null
                    ? null
                    : DecorationImage(
                        image: context.read<ImageStorage>().provider(story.imageUrl)!,
                        fit: BoxFit.cover,
                        colorFilter: const ColorFilter.mode(Color(0x55000000), BlendMode.darken),
                      ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < state.stories.length; i++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: AnimatedBuilder(
                                  animation: _progress,
                                  builder: (context, _) => ProgressBar(
                                    value: i < state.index ? 1 : (i == state.index ? _progress.value : 0),
                                    color: Colors.white,
                                    height: 3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          UserAvatar(name: story.authorName, imageUrl: story.authorAvatarUrl, size: 40),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.authorName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${story.type.label} · ${Formatters.relative(story.createdAt)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => _close(context),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        story.text,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, height: 1.3),
                      ),
                      const Spacer(),
                      if (state.rewardMessage != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Chip(
                              avatar: const Icon(Icons.monetization_on_rounded, color: AppColors.gold),
                              label: Text(state.rewardMessage!),
                            ),
                          ),
                        ),
                      if (story.postId != null)
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: colors.last),
                          onPressed: () {
                            _progress.stop();
                            context.pushReplacement(AppRoutes.post(story.postId!));
                          },
                          child: const Text('Ver publicação'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
