import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/app_icons.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/widgets/widgets.dart';
import 'edit_profile_cubit.dart';

/// "Editar Perfil": dados básicos + título e selos exibidos no perfil.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  static Widget route(BuildContext context) => BlocProvider(
    create: (context) => EditProfileCubit(
      context.read<UserRepository>(),
      context.read<GamificationRepository>(),
      context.read<SessionCubit>(),
    )..load(),
    child: const EditProfilePage(),
  );

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _initial = context.read<EditProfileCubit>().state.user;
  late final _name = TextEditingController(text: _initial.name);
  late final _username = TextEditingController(text: _initial.username);
  late final _bio = TextEditingController(text: _initial.bio);
  late String _pronouns = _initial.pronouns.isEmpty ? 'Ele/dele' : _initial.pronouns;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditProfileCubit, EditProfileState>(
      listener: (context, state) {
        if (state.error != null) context.showMessage(state.error!, error: true);
        if (state.saved) {
          context.showMessage('Perfil atualizado!');
          context.pop();
        }
      },
      listenWhen: (a, b) => a.error != b.error || a.saved != b.saved,
      builder: (context, state) {
        final cubit = context.read<EditProfileCubit>();
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(fallback: AppRoutes.profile),
            title: const Text('Editar Perfil'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Center(
                child: AvatarPicker(
                  name: _name.text,
                  imageUrl: state.user.avatarUrl,
                  size: 104,
                  onChanged: cubit.setAvatar,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(label: 'Nome', controller: _name, onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nome de usuário @',
                controller: _username,
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
              ),
              const SizedBox(height: 16),
              const Text('Pronomes', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in const ['Ele/dele', 'Ela/dela', 'Elu/delu'])
                    ChoiceChip(
                      label: Text(p),
                      selected: _pronouns == p,
                      onSelected: (_) => setState(() => _pronouns = p),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Bio', controller: _bio, maxLines: 3),
              const SizedBox(height: 24),
              Text('Título', style: context.text.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Nenhum'),
                    selected: state.user.titleId == null,
                    onSelected: (_) => cubit.selectTitle(null),
                  ),
                  for (final title in state.ownedTitles)
                    ChoiceChip(
                      label: Text(title.name),
                      selected: state.user.titleId == title.id,
                      onSelected: (_) => cubit.selectTitle(title.id),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Text('Selos exibidos', style: context.text.titleMedium)),
                  Text(
                    '${state.user.badgeIds.length}/${EditProfileCubit.maxBadges}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final badge in state.ownedBadges)
                    _BadgeOption(
                      icon: AppIcons.byKey(badge.icon),
                      label: badge.name,
                      selected: state.user.badgeIds.contains(badge.id),
                      onTap: () => cubit.toggleBadge(badge.id),
                    ),
                  _BadgeOption(
                    icon: Icons.add_rounded,
                    label: 'Mais selos',
                    selected: false,
                    onTap: () => context.push(AppRoutes.rewards),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Salvar',
                loading: state.saving,
                onPressed: () =>
                    cubit.save(name: _name.text, username: _username.text, bio: _bio.text, pronouns: _pronouns),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.read<SessionCubit>().logout();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Sair da conta'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BadgeOption extends StatelessWidget {
  const _BadgeOption({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: selected ? Colors.white : AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
