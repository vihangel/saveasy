import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../shared/data/datasources/mock_seed.dart';
import '../../../shared/utils/context_x.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/widgets.dart';
import 'forgot_password_cubit.dart';

/// Escuta o cubit do fluxo e navega quando um passo é concluído.
class _StepListener extends StatelessWidget {
  const _StepListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status.isFailure) return context.showMessage(state.error!, error: true);
        if (!state.status.isSuccess || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
        switch (state.step) {
          case ForgotPasswordStep.code:
            context.push(AppRoutes.forgotCode);
          case ForgotPasswordStep.newPassword:
            context.push(AppRoutes.resetPassword);
          case ForgotPasswordStep.done:
            context.showMessage('Senha alterada! Faça login com a nova senha.');
            context.go(AppRoutes.login);
          case ForgotPasswordStep.email:
            break;
        }
      },
      child: child,
    );
  }
}

/// Rec. Senha 1
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((ForgotPasswordCubit c) => c.state.status.isLoading);
    return _StepListener(
      child: IllustratedScaffold(
        image: 'assets/images/header_forgot.png',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              AppTextField(
                label: 'E-mail',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Enviar código',
                loading: loading,
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    context.read<ForgotPasswordCubit>().sendCode(_email.text);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Validate código
class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({super.key});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ForgotPasswordCubit>().state;
    return _StepListener(
      child: IllustratedScaffold(
        image: 'assets/images/header_code.png',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Enviamos um código de 5 dígitos para\n${state.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 5,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 36, letterSpacing: 16, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: '#####',
                counterText: '',
                contentPadding: EdgeInsets.symmetric(vertical: 24),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Inserir código',
              loading: state.status.isLoading,
              onPressed: () => context.read<ForgotPasswordCubit>().verifyCode(_code.text),
            ),
            const SizedBox(height: 12),
            const Text(
              'Protótipo: use o código ${MockSeed.verificationCode}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rec. Senha 2
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((ForgotPasswordCubit c) => c.state.status.isLoading);
    return _StepListener(
      child: IllustratedScaffold(
        image: 'assets/images/header_reset.png',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              AppTextField(label: 'Nova senha', controller: _password, obscure: true, validator: Validators.password),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirmar senha',
                obscure: true,
                validator: (v) => v == _password.text ? null : 'As senhas não conferem',
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Salvar senha',
                loading: loading,
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    context.read<ForgotPasswordCubit>().resetPassword(_password.text);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
