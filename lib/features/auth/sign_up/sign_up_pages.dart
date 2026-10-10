import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../shared/data/datasources/mock_seed.dart';
import '../../../app/env.dart';
import '../../../shared/utils/context_x.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/widgets.dart';
import 'sign_up_cubit.dart';

/// "Sign Up Page": e-mail, senha, termos e login social.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showTerms() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Text(
            'Termos de uso (rascunho)\n\nAo criar uma conta você concorda em usar o Save Easy para compartilhar e '
            'apoiar boas ações de forma honesta, respeitar as outras pessoas e não publicar conteúdo falso ou '
            'ofensivo. O texto definitivo dos termos e da política de privacidade está em elaboração.',
          ),
        ),
      ),
    );
  }

  void _submit(SignUpCubit cubit) {
    if (cubit.state.status.isLoading) return;
    if (_form.currentState!.validate()) {
      TextInput.finishAutofillContext();
      cubit.submit(email: _email.text, password: _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpCubit, SignUpState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status.isFailure) return context.showMessage(state.error!, error: true);
        if (state.status.isSuccess && state.awaitingCode && (ModalRoute.of(context)?.isCurrent ?? false)) {
          context.push(AppRoutes.signUpVerify);
        }
      },
      builder: (context, state) {
        final cubit = context.read<SignUpCubit>();
        return IllustratedScaffold(
          image: 'assets/images/header_login.png',
          onBack: () => AppBackButton.goBack(context, fallback: AppRoutes.login),
          child: Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Criar conta', style: context.text.headlineSmall),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'E-mail',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Senha',
                    controller: _password,
                    obscure: true,
                    hint: 'Mínimo 8 caracteres, com letras e números',
                    validator: Validators.password,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Confirmar senha',
                    obscure: true,
                    validator: Validators.confirmPassword(() => _password.text),
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(cubit),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: state.acceptedTerms,
                    onChanged: (v) => cubit.toggleTerms(v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Wrap(
                      children: [
                        const Text('Li e concordo com os '),
                        Semantics(
                          link: true,
                          child: InkWell(
                            onTap: _showTerms,
                            child: const Text('termos de uso', style: TextStyle(color: AppColors.link)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Criar conta', loading: state.status.isLoading, onPressed: () => _submit(cubit)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Já tenho conta · Entrar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Código de confirmação do e-mail (6 dígitos).
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpCubit, SignUpState>(
      listenWhen: (a, b) => a.status != b.status || a.message != b.message,
      listener: (context, state) {
        if (state.status.isFailure) context.showMessage(state.error!, error: true);
        if (state.message != null) context.showMessage(state.message!);
      },
      builder: (context, state) {
        final cubit = context.read<SignUpCubit>();
        return IllustratedScaffold(
          image: 'assets/images/header_code.png',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Confirme seu e-mail', textAlign: TextAlign.center, style: context.text.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Enviamos um código de 6 números para\n${state.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              CodeField(controller: _code, onCompleted: cubit.verify),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Confirmar',
                loading: state.status.isLoading,
                onPressed: () => cubit.verify(_code.text),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: cubit.resend, child: const Text('Reenviar código')),
              const Text(
                'Não chegou? Confira o spam. O link do e-mail também confirma a conta.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if (!Env.useSupabase)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Modo demonstração: use o código ${MockSeed.verificationCode}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Campo grande para códigos numéricos (confirmação e recuperação de senha).
class CodeField extends StatelessWidget {
  const CodeField({super.key, required this.controller, this.onCompleted, this.length = 6});

  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final int length;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      maxLength: length,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) {
        if (v.length == length) onCompleted?.call(v);
      },
      style: const TextStyle(fontSize: 32, letterSpacing: 12, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: '•' * length,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}
