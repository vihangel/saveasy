import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../shared/data/models/models.dart';
import '../../../shared/services/cep_service.dart';
import '../../../shared/utils/context_x.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/widgets.dart';
import 'onboarding_cubit.dart';

/// Navega para o próximo passo quando o cubit avança.
class _StepListener extends StatelessWidget {
  const _StepListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listenWhen: (a, b) => a.status != b.status || a.step != b.step,
      listener: (context, state) {
        if (state.status.isFailure) return context.showMessage(state.error!, error: true);
        if (!state.status.isSuccess || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
        switch (state.step) {
          case OnboardingStep.profile:
            context.push(AppRoutes.onboardingProfile);
          case OnboardingStep.address:
            context.push(AppRoutes.onboardingAddress);
          case OnboardingStep.done:
            context.showMessage('Perfil pronto! Você ganhou 100 moedas de boas-vindas 🎉');
          case OnboardingStep.accountType:
            break;
        }
      },
      child: child,
    );
  }
}

/// "Tipo de conta". O voltar pergunta se quer sair (anotação do Figma); a conta
/// continua criada e o perfil pode ser completado depois.
class AccountTypePage extends StatelessWidget {
  const AccountTypePage({super.key});

  Future<void> _confirmExit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair por enquanto?'),
        content: const Text('Sua conta já foi criada. Você pode completar o perfil quando entrar de novo.'),
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
    if ((leave ?? false) && context.mounted) context.read<OnboardingCubit>().leave();
  }

  @override
  Widget build(BuildContext context) {
    final selected = context.select((OnboardingCubit c) => c.state.accountType);
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
              Text('Como você vai usar o Save Easy?', style: context.text.titleLarge),
              const SizedBox(height: 4),
              const Text(
                'Escolha o tipo de conta. Comunidades e empresas passam por verificação para receber doações.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              for (final type in AccountType.values) ...[
                _AccountTypeCard(
                  type: type,
                  selected: type == selected,
                  onTap: () => context.read<OnboardingCubit>().selectAccountType(type),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              PrimaryButton(label: 'Próximo', onPressed: context.read<OnboardingCubit>().confirmAccountType),
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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
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
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

/// Perfil: foto, nome, @, pronomes e nascimento.
class OnboardingProfilePage extends StatefulWidget {
  const OnboardingProfilePage({super.key});

  @override
  State<OnboardingProfilePage> createState() => _OnboardingProfilePageState();
}

class _OnboardingProfilePageState extends State<OnboardingProfilePage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<OnboardingCubit>().state.name);
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
    if (date != null && mounted) context.read<OnboardingCubit>().selectBirthDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingCubit>().state;
    final cubit = context.read<OnboardingCubit>();
    final isPerson = state.accountType == AccountType.personal || state.accountType == AccountType.influencer;
    return _StepListener(
      child: IllustratedScaffold(
        header: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: AvatarPicker(name: _name.text, imageUrl: state.avatarUrl, size: 132, onChanged: cubit.setAvatar),
          ),
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: isPerson ? 'Nome completo' : 'Nome da ${state.accountType.label.toLowerCase()}',
                controller: _name,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nome de usuário @',
                controller: _username,
                hint: 'ex.: maria.cuiaba',
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                  LengthLimitingTextInputFormatter(30),
                ],
                validator: (v) => (v ?? '').trim().length < 3 ? 'Use ao menos 3 caracteres' : null,
              ),
              if (isPerson) ...[
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
                        onSelected: (_) => cubit.selectPronouns(p),
                      ),
                  ],
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
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Próximo',
                loading: state.status.isLoading,
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    cubit.submitProfile(name: _name.text, username: _username.text);
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

/// Endereço: começa em Cuiabá-MT (foco do lançamento) e o CEP preenche o resto.
class OnboardingAddressPage extends StatefulWidget {
  const OnboardingAddressPage({super.key});

  @override
  State<OnboardingAddressPage> createState() => _OnboardingAddressPageState();
}

class _OnboardingAddressPageState extends State<OnboardingAddressPage> {
  final _form = GlobalKey<FormState>();
  final _cep = TextEditingController();
  final _street = TextEditingController();
  final _complement = TextEditingController();
  final _city = TextEditingController(text: 'Cuiabá');
  final _cepService = CepService();
  String? _state = 'MT';
  bool _searching = false;

  static const _states = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', //
    'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  @override
  void dispose() {
    for (final c in [_cep, _street, _complement, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _lookupCep(String value) async {
    if (value.length != 8) return;
    setState(() => _searching = true);
    final result = await _cepService.lookup(value);
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (result != null) {
        _street.text = [result.street, result.neighborhood].where((s) => s.isNotEmpty).join(', ');
        _city.text = result.city;
        _state = result.state;
      }
    });
    if (result == null) context.showMessage('CEP não encontrado. Preencha o endereço.', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingCubit>().state;
    final cubit = context.read<OnboardingCubit>();
    return _StepListener(
      child: IllustratedScaffold(
        image: 'assets/images/header_signup_address.png',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Usamos sua cidade para mostrar ações perto de você. O endereço completo não aparece no perfil.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'CEP',
                controller: _cep,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                onChanged: _lookupCep,
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                validator: Validators.cep,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Endereço (rua, número e bairro)',
                controller: _street,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Complemento', controller: _complement),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(label: 'Cidade', controller: _city, validator: Validators.required),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('UF', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_state),
                          isExpanded: true,
                          initialValue: _state,
                          items: [for (final s in _states) DropdownMenuItem(value: s, child: Text(s))],
                          onChanged: (v) => setState(() => _state = v),
                          validator: (v) => v == null ? 'UF' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: state.emailNews,
                onChanged: (v) => cubit.toggleEmailNews(v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Quero receber novidades por e-mail'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Finalizar',
                loading: state.status.isLoading,
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  cubit.submitAddress(
                    Address(
                      cep: _cep.text,
                      street: _street.text,
                      complement: _complement.text,
                      state: _state!,
                      city: _city.text.trim(),
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
