import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';

/// Períodos do filtro do currículo.
enum ResumePeriod {
  week('7 dias', 7),
  month('30 dias', 30),
  year('12 meses', 365),
  all('Tudo', null);

  const ResumePeriod(this.label, this.days);

  final String label;
  final int? days;
}

/// Currículo de ações e álbum em tela cheia (link direto).
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppPage(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Atividades'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Currículo'),
              Tab(text: 'Álbum'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ActionResumeView(profileId: profileId),
            PhotoAlbumView(profileId: profileId),
          ],
        ),
      ),
    );
  }
}

/// Currículo de ações: o que a pessoa fez, filtrado por período.
class ActionResumeView extends StatefulWidget {
  const ActionResumeView({super.key, required this.profileId});

  final String profileId;

  @override
  State<ActionResumeView> createState() => _ActionResumeViewState();
}

class _ActionResumeViewState extends State<ActionResumeView> {
  ResumePeriod _period = ResumePeriod.all;
  late Future<ActionResume> _resume = _load();

  Future<ActionResume> _load() {
    final days = _period.days;
    return context.read<GamificationRepository>().actionResume(
      widget.profileId,
      from: days == null ? null : DateTime.now().subtract(Duration(days: days)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              for (final p in ResumePeriod.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p.label),
                    selected: p == _period,
                    onSelected: (_) => setState(() {
                      _period = p;
                      _resume = _load();
                    }),
                  ),
                ),
            ],
          ),
        ),
        FutureBuilder<ActionResume>(
          future: _resume,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
            }
            final resume = snapshot.data;
            if (resume == null) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      _Total(value: resume.totals['participations'] ?? 0, label: 'Ações'),
                      _Total(value: resume.totals['posts'] ?? 0, label: 'Publicações'),
                      _Total(value: resume.totals['donations'] ?? 0, label: 'Doações'),
                    ],
                  ),
                ),
                if (resume.items.isEmpty) const EmptyState(message: 'Nada neste período.', icon: Icons.history_rounded),
                for (final item in resume.items)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: PostCover.colorsFor(item.type).first.withValues(alpha: 0.2),
                      child: Icon(_icon(item.kind), color: PostCover.colorsFor(item.type).last),
                    ),
                    title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${item.kind.label} · ${Formatters.date(item.date.toLocal())}'),
                    trailing: item.coins > 0 ? CoinChip(coins: item.coins, prefix: '+') : null,
                    onTap: item.postId == null ? null : () => context.push(AppRoutes.post(item.postId!)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  IconData _icon(ResumeKind kind) => switch (kind) {
    ResumeKind.participation => Icons.event_available_rounded,
    ResumeKind.attended => Icons.verified_rounded,
    ResumeKind.post => Icons.edit_note_rounded,
    ResumeKind.donation => Icons.volunteer_activism_rounded,
    ResumeKind.itemReceived => Icons.redeem_rounded,
  };
}

/// Álbum: fotos que a pessoa enviou nas ações.
class PhotoAlbumView extends StatefulWidget {
  const PhotoAlbumView({super.key, required this.profileId});

  final String profileId;

  @override
  State<PhotoAlbumView> createState() => _PhotoAlbumViewState();
}

class _PhotoAlbumViewState extends State<PhotoAlbumView> {
  late final Future<List<PostPhoto>> _album = context.read<EngagementRepository>().album(widget.profileId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PostPhoto>>(
      future: _album,
      builder: (context, snapshot) {
        final photos = snapshot.data;
        if (snapshot.hasError) return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
        if (photos == null) return const Center(child: CircularProgressIndicator());
        if (photos.isEmpty) {
          return const EmptyState(
            message: 'As fotos enviadas nas ações aparecem aqui.',
            icon: Icons.photo_library_outlined,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, i) => InkWell(
            onTap: () => context.push(AppRoutes.post(photos[i].postId)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppImage(reference: photos[i].imageUrl),
            ),
          ),
        );
      },
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
