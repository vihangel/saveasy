import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'profile_cubit.freezed.dart';
part 'profile_state.dart';

/// Perfil próprio e de outros usuários (pessoal, influencer, comunidade, empresa).
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required this.userId,
    required this._users,
    required this._posts,
    required this._gamification,
    required this._wallet,
    required this._session,
  }) : super(const ProfileState());

  final String userId;
  final UserRepository _users;
  final PostRepository _posts;
  final GamificationRepository _gamification;
  final WalletRepository _wallet;
  final SessionCubit _session;

  Future<void> load() async {
    emit(state.copyWith(status: state.user == null ? ViewStatus.loading : state.status));
    try {
      final isMe = userId == _session.user.id;
      final (user, posts) = await (_users.getById(userId), _posts.byAuthor(userId)).wait;
      final history = isMe ? await _wallet.history() : <WalletTransaction>[];
      emit(
        state.copyWith(
          status: ViewStatus.success,
          user: user,
          posts: posts,
          isMe: isMe,
          history: history,
          badges: _gamification.rewardsByIds(user.badgeIds),
          title: user.titleId == null ? null : _gamification.rewardsByIds([user.titleId!]).firstOrNull,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ViewStatus.failure, error: 'Perfil não encontrado.'));
    }
  }

  Future<void> toggleFollow() async {
    final me = await _users.toggleFollow(meId: _session.user.id, targetId: userId);
    _session.updateUser(me);
    emit(state.copyWith(user: await _users.getById(userId)));
  }
}
