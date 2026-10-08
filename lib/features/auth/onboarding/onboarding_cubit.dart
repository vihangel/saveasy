import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/data/models/models.dart';
import '../../../shared/data/repositories/repositories.dart';
import '../../../shared/notifiers/session_cubit.dart';
import '../../../shared/utils/view_status.dart';

part 'onboarding_cubit.freezed.dart';
part 'onboarding_state.dart';

/// Completar perfil depois de criar a conta: tipo → perfil → endereço.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._auth, this._session) : super(OnboardingState(name: _session.state.userOrNull?.name ?? ''));

  final AuthRepository _auth;
  final SessionCubit _session;

  void selectAccountType(AccountType type) => emit(state.copyWith(accountType: type));

  void confirmAccountType() => emit(state.copyWith(step: OnboardingStep.profile, status: ViewStatus.success));

  void selectPronouns(String value) => emit(state.copyWith(pronouns: value));

  void selectBirthDate(DateTime value) => emit(state.copyWith(birthDate: value));

  void setAvatar(String? url) => emit(state.copyWith(avatarUrl: url));

  void toggleEmailNews(bool value) => emit(state.copyWith(emailNews: value));

  Future<void> submitProfile({required String name, required String username}) async {
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    try {
      if (!await _auth.isUsernameAvailable(username)) {
        return emit(state.copyWith(status: ViewStatus.failure, error: 'Esse nome de usuário já está em uso.'));
      }
      emit(
        state.copyWith(
          name: name.trim(),
          username: username.trim().toLowerCase(),
          step: OnboardingStep.address,
          status: ViewStatus.success,
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }

  Future<void> submitAddress(Address address) async {
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    try {
      final user = await _auth.completeProfile(
        ProfileCompletion(
          accountType: state.accountType,
          name: state.name,
          username: state.username,
          pronouns: state.pronouns,
          birthDate: state.birthDate,
          address: address,
          emailNews: state.emailNews,
          avatarUrl: state.avatarUrl,
        ),
      );
      emit(state.copyWith(step: OnboardingStep.done, status: ViewStatus.success));
      // Com o perfil completo o router leva para o início.
      _session.updateUser(user);
    } on AppException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }

  Future<void> leave() => _session.logout();
}
