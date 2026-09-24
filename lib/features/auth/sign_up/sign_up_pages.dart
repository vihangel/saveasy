import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../shared/data/models/models.dart';
import '../../../shared/utils/context_x.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/widgets.dart';
import 'sign_up_cubit.dart';

/// Navega para o próximo passo quando o cubit avança.
class _StepListener extends StatelessWidget {
  const _StepListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpCubit, SignUpState>(
      listenWhen: (a, b) => a.status != b.status || a.step != b.step,
      listener: (context, state) {
        if (state.status.isFailure) return context.showMessage(state.error!, error: true);
        if (!state.status.isSuccess || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
        switch (state.step) {
          case SignUpStep.credentials:
            context.push(AppRoutes.signUpCredentials);
          case SignUpStep.profile:
            context.push(AppRoutes.signUpProfile);
          case SignUpStep.address:
            context.push(AppRoutes.signUpAddress);
          case SignUpStep.done:
            context.go(AppRoutes.signUpSuccess);
          case SignUpStep.accountType:
            break;
        }
      },
      child: child,
    );
  }
}

/// "Tipo de conta" — o voltar pergunta se deseja sair da criação de conta
/// (anotação do Figma).
class AccountTypePage extends StatelessWidget {
  const AccountTypePage({super.key});

  Future<void> _confirmExit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do cadastro?'),
        content: const Text('Os dados preenchidos até agora serão perdidos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continuar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if ((leave ?? false) && context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final selected = context.select((SignUpCubit c) => c.state.accountType);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: _StepListener(
        child: IllustratedScaffold(
          image: 'assets/images/header_account_type.png',
          onBack: () => _confirmExit(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Para começar, precisamos que você escolha o tipo de conta que deseja criar.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              for (final type in AccountType.values) ...[
                _AccountTypeCard(
                  type: type,
                  selected: type == selected,
                  onTap: () => context.read<SignUpCubit>().selectAccountType(type),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              PrimaryButton(label: 'Próximo', onPressed: context.read<SignUpCubit>().confirmAccountType),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({required this.type, required this.selected, required this.onTap});

  final AccountType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/account_type_thumb.png', width: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(type.description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Passo 2 — e-mail e senha.
class SignUpCredentialsPage extends StatefulWidget {
  const SignUpCredentialsPage({super.key});

  @override
  State<SignUpCredentialsPage> createState() => _SignUpCredentialsPageState();
}

class _SignUpCredentialsPageState extends State<SignUpCredentialsPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: context.read<SignUpCubit>().state.email);
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SignUpCubit>().state;
    final cubit = context.read<SignUpCubit>();
    return _StepListener(
      child: IllustratedScaffold(
        image: 'assets/images/header_signup_credentials.png',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Senha', controller: _password, obscure: true, validator: Validators.password),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Repita a senha',
                obscure: true,
                validator: (v) => v == _password.text ? null : 'As senhas não conferem',
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: state.acceptedTerms,
                onChanged: (v) => cubit.toggleTerms(v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text.rich(
                  TextSpan(
                    text: 'Concordo com os ',
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => _showTerms(context),
                          child: const Text('termos.', style: TextStyle(color: AppColors.link)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CheckboxListTile(
                value: state.emailNews,
                onChanged: (v) => cubit.toggleEmailNews(v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Receber novidades por E-mail.'),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Próximo',
                loading: state.status.isLoading,
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    cubit.submitCredentials(email: _email.text, password: _password.text);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Termos de uso (placeholder)\n\nAo criar uma conta você concorda em usar o Save Easy para '
          'compartilhar e apoiar boas ações de forma honesta. O texto definitivo dos termos ainda '
          'precisa ser escrito.',
        ),
      ),
    );
  }
}

/// Passo 3 — dados do perfil.
class SignUpProfilePage extends StatefulWidget {
  const SignUpProfilePage({super.key});

  @override
  State<SignUpProfilePage> createState() => _SignUpProfilePageState();
}

class _SignUpProfilePageState extends State<SignUpProfilePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();

  static const _pronouns = ['Ele/dele', 'Ela/dela', 'Elu/delu'];

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1920),
      lastDate: now,
      initialDate: DateTime(now.year - 18),
    );
    if (date != null && mounted) context.read<SignUpCubit>().selectBirthDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SignUpCubit>().state;
    return _StepListener(
      child: IllustratedScaffold(
        header: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 90,
              margin: const EdgeInsets.only(top: 80),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AvatarPicker(
                name: _name.text,
                imageUrl: state.avatarUrl,
                onChanged: context.read<SignUpCubit>().setAvatar,
              ),
            ),
          ],
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(label: 'Nome completo', controller: _name, validator: Validators.required),
              const SizedBox(height: 16),
              const Text('Pronomes', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                children: [
                  for (final p in _pronouns)
                    ChoiceChip(
                      label: Text(p),
                      selected: state.pronouns == p,
                      showCheckmark: false,
                      selectedColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: state.pronouns == p ? AppColors.primary : Colors.transparent),
                      onSelected: (_) => context.read<SignUpCubit>().selectPronouns(p),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nome de usuário @',
                controller: _username,
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]'))],
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              AppTextField(
                key: ValueKey(state.birthDate),
                label: 'Data de nascimento',
                readOnly: true,
                initialValue: state.birthDate == null ? '' : Formatters.date(state.birthDate!),
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                onTap: _pickDate,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Próximo',
                loading: state.status.isLoading,
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    context.read<SignUpCubit>().submitProfile(name: _name.text, username: _username.text);
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

/// Passo 4 — endereço.
class SignUpAddressPage extends StatefulWidget {
  const SignUpAddressPage({super.key});

  @override
  State<SignUpAddressPage> createState() => _SignUpAddressPageState();
}

class _SignUpAddressPageState extends State<SignUpAddressPage> {
  final _form = GlobalKey<FormState>();
  final _cep = TextEditingController();
  final _street = TextEditingController();
  final _complement = TextEditingController();
  final _city = TextEditingController();
  String? _state;

  static const _states = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];

  @override
  void dispose() {
    for (final c in [_cep, _street, _complement, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((SignUpCubit c) => c.state.status.isLoading);
    return _StepListener(
      child: IllustratedScaffold(
        image: 'assets/images/header_signup_address.png',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'CEP',
                controller: _cep,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                validator: Validators.cep,
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Endereço (Rua/bairro/número)', controller: _street, validator: Validators.required),
              const SizedBox(height: 16),
              AppTextField(label: 'Complemento', controller: _complement),
              const SizedBox(height: 16),
              const Text('Estado', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _state,
                items: [for (final s in _states) DropdownMenuItem(value: s, child: Text(s))],
                onChanged: (v) => setState(() => _state = v),
                validator: (v) => v == null ? 'Selecione o estado' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Cidade', controller: _city, validator: Validators.required),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Finalizar',
                loading: loading,
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  context.read<SignUpCubit>().submitAddress(
                    Address(
                      cep: _cep.text,
                      street: _street.text,
                      complement: _complement.text,
                      state: _state!,
                      city: _city.text,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Passo 5 — conta criada.
class SignUpSuccessPage extends StatelessWidget {
  const SignUpSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return IllustratedScaffold(
      image: 'assets/images/header_signup_success.png',
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Uhuu!\nSua conta foi criada',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          const Text(
            'Para começar a compartilhar e apoiar as boas ações, é necessário verificar o link de '
            'ativação que foi enviado para o seu email cadastrado.\n\n'
            'Verifique também a sua caixa de spam, caso não encontre o email na sua caixa de entrada.\n\n'
            'Estamos ansiosos para ver como você vai ajudar a mudar o mundo com as suas boas ações!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Fazer login', onPressed: () => context.go(AppRoutes.login)),
        ],
      ),
    );
  }
}
