import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/data/models/models.dart';
import '../../../shared/data/repositories/repositories.dart';
import '../../../shared/utils/view_status.dart';

part 'sign_up_cubit.freezed.dart';
part 'sign_up_state.dart';

/// Guarda os dados dos passos do cadastro até a criação da conta.
class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this._auth) : super(const SignUpState());

  final AuthRepository _auth;

  void selectAccountType(AccountType type) => emit(state.copyWith(accountType: type));

  void confirmAccountType() => emit(state.copyWith(step: SignUpStep.credentials, status: ViewStatus.success));

  void toggleTerms(bool value) => emit(state.copyWith(acceptedTerms: value));

  void toggleEmailNews(bool value) => emit(state.copyWith(emailNews: value));

  void selectPronouns(String value) => emit(state.copyWith(pronouns: value));

  void selectBirthDate(DateTime value) => emit(state.copyWith(birthDate: value));

  void setAvatar(String? reference) => emit(state.copyWith(avatarUrl: reference));

  Future<void> submitCredentials({required String email, required String password}) async {
    if (!state.acceptedTerms) {
      return emit(state.copyWith(status: ViewStatus.failure, error: 'Você precisa aceitar os termos.'));
    }
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    if (await _auth.emailExists(email)) {
      return emit(state.copyWith(status: ViewStatus.failure, error: 'Já existe uma conta com esse e-mail.'));
    }
    emit(state.copyWith(email: email.trim(), password: password, step: SignUpStep.profile, status: ViewStatus.success));
  }

  Future<void> submitProfile({required String name, required String username}) async {
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    if (await _auth.usernameExists(username.replaceAll('@', ''))) {
      return emit(state.copyWith(status: ViewStatus.failure, error: 'Esse nome de usuário já está em uso.'));
    }
    emit(state.copyWith(name: name, username: username, step: SignUpStep.address, status: ViewStatus.success));
  }

  Future<void> submitAddress(Address address) async {
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    try {
      await _auth.register(
        SignUpData(
          accountType: state.accountType,
          email: state.email,
          password: state.password,
          name: state.name,
          username: state.username,
          pronouns: state.pronouns,
          birthDate: state.birthDate,
          address: address,
          emailNews: state.emailNews,
          avatarUrl: state.avatarUrl,
        ),
      );
      emit(state.copyWith(step: SignUpStep.done, status: ViewStatus.success));
    } on AppException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }
}
