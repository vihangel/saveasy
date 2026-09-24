import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../data/models/models.dart';
import '../notifiers/session_cubit.dart';

extension ContextX on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;

  /// Fator de escala de texto do sistema (acessibilidade). Usado para dimensionar
  /// alturas fixas, como listas horizontais.
  double get textScale => MediaQuery.textScalerOf(this).scale(1);

  /// Usuário logado (use apenas em telas protegidas).
  AppUser get currentUser => read<SessionCubit>().user;

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? AppColors.danger : AppColors.textDark));
  }
}
