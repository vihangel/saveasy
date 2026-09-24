import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../shared/data/datasources/mock_seed.dart';
import '../../../shared/utils/context_x.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/widgets.dart';
import 'login_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      context.read<LoginCubit>().login(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status.isFailure) context.showMessage(state.error!, error: true);
      },
      builder: (context, state) {
        return IllustratedScaffold(
          image: 'assets/images/header_login.png',
          showBack: false,
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'E-mail',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Senha',
                  controller: _password,
                  obscure: true,
                  validator: (v) => Validators.required(v, 'Informe a senha'),
                  onSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.link,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('esqueceu a senha?'),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(label: 'Login', loading: state.status.isLoading, onPressed: _submit),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Ou entre com:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      color: const Color(0xFF1453C8),
                      child: const Text(
                        'f',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      onTap: () => context.read<LoginCubit>().loginWithProvider('facebook'),
                    ),
                    const SizedBox(width: 20),
                    _SocialButton(
                      color: Colors.white,
                      child: const Text(
                        'G',
                        style: TextStyle(color: Color(0xFFEA4335), fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      onTap: () => context.read<LoginCubit>().loginWithProvider('google'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: () => context.push(AppRoutes.signUp), child: const Text('Criar conta')),
                const SizedBox(height: 8),
                const Text(
                  'Conta de teste: ${MockSeed.demoEmail} / ${MockSeed.demoPassword}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.color, required this.child, required this.onTap});

  final Color color;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: child,
      ),
    );
  }
}
