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
import '../../shared/utils/links.dart';

/// Evento Confirmado 1/2. Só exibe dados, então usa um FutureBuilder
/// em vez de um cubit próprio.
class EventConfirmedPage extends StatelessWidget {
  const EventConfirmedPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.userOrNull);
    return Scaffold(
      body: FutureBuilder<Post>(
        future: context.read<PostRepository>().getById(postId),
        builder: (context, snapshot) {
          final post = snapshot.data;
          if (post == null || user == null) return const Center(child: CircularProgressIndicator());
          return RewardSuccessView(
            icon: Icons.celebration_rounded,
            title: 'Presença confirmada!',
            message:
                '${post.title}\n'
                '${post.startsAt == null ? '' : Formatters.dateTime(post.startsAt!)}\n'
                '${post.link ?? post.location ?? ''}',
            user: user,
            coins: post.rewardCoins,
            xp: post.rewardXp,
            actions: [
              if (post.startsAt != null) ...[
                PrimaryButton(
                  label: 'Adicionar ao calendário',
                  icon: Icons.event_available_rounded,
                  onPressed: () async {
                    final opened = await openExternalLink(_calendarUrl(post));
                    if (!opened && context.mounted) {
                      context.showMessage('Não foi possível abrir o calendário.', error: true);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(onPressed: () => context.go(AppRoutes.home), child: const Text('Voltar ao início')),
              const SizedBox(height: 8),
              Text(
                post.attending == 1
                    ? '1 pessoa confirmada'
                    : '${Formatters.compact(post.attending)} pessoas confirmadas',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Link do Google Agenda já preenchido (funciona na web e no celular).
  static String _calendarUrl(Post post) {
    String stamp(DateTime d) => '${d.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';
    final start = post.startsAt!;
    final end = post.endsAt != null && post.endsAt!.isAfter(start) ? post.endsAt! : start.add(const Duration(hours: 2));
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': post.title,
      'dates': '${stamp(start)}/${stamp(end)}',
      'details': post.description,
      if ((post.location ?? post.link) != null) 'location': post.location ?? post.link!,
    }).toString();
  }
}
