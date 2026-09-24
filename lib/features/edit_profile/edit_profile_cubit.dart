import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'edit_profile_cubit.freezed.dart';
part 'edit_profile_state.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit(this._users, this._gamification, this._session) : super(EditProfileState(user: _session.user));

  final UserRepository _users;
  final GamificationRepository _gamification;
  final SessionCubit _session;

  static const maxBadges = 3;

  Future<void> load() async {
    final owned = (await _gamification.rewards()).where((r) => r.owned).toList();
    emit(
      state.copyWith(
        status: ViewStatus.success,
        ownedBadges: owned.where((r) => r.kind == RewardKind.badge).toList(),
        ownedTitles: owned.where((r) => r.kind == RewardKind.title).toList(),
      ),
    );
  }

  void setAvatar(String? reference) => emit(state.copyWith(user: state.user.copyWith(avatarUrl: reference)));

  void selectTitle(String? id) => emit(state.copyWith(user: state.user.copyWith(titleId: id)));

  void toggleBadge(String id) {
    final badges = state.user.badgeIds;
    if (badges.contains(id)) {
      return emit(state.copyWith(user: state.user.copyWith(badgeIds: badges.where((b) => b != id).toList())));
    }
    if (badges.length >= maxBadges) {
      return emit(state.copyWith(error: 'Você pode exibir até $maxBadges selos.'));
    }
    emit(state.copyWith(user: state.user.copyWith(badgeIds: [...badges, id]), error: null));
  }

  Future<void> save({
    required String name,
    required String username,
    required String bio,
    required String pronouns,
  }) async {
    if (name.trim().isEmpty || username.trim().isEmpty) {
      return emit(state.copyWith(error: 'Nome e usuário são obrigatórios.'));
    }
    emit(state.copyWith(saving: true, error: null));
    final updated = await _users.update(
      state.user.copyWith(
        name: name.trim(),
        username: username.trim().replaceAll('@', ''),
        bio: bio.trim(),
        pronouns: pronouns,
      ),
    );
    _session.updateUser(updated);
    emit(state.copyWith(saving: false, saved: true, user: updated));
  }
}
