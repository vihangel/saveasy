import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../shared/notifiers/session_cubit.dart';

/// Abertura / tela de carregamento. O redirecionamento é feito pelo router
/// assim que a sessão é restaurada.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.read<SessionCubit>().restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 180),
            const SizedBox(height: 16),
            Text('SavEasy', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 80),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
