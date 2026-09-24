import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'create_post_cubit.dart';

/// Formulários "Criar Evento / Doação / Ação social / Tutorial / Atividades /
/// Propaganda". Os campos variam conforme o tipo.
class CreatePostFormPage extends StatefulWidget {
  const CreatePostFormPage({super.key});

  static Widget route(BuildContext context, PostType type) => BlocProvider(
    create: (context) => CreatePostCubit(type, context.read<PostRepository>(), context.read<SessionCubit>()),
    child: const CreatePostFormPage(),
  );

  @override
  State<CreatePostFormPage> createState() => _CreatePostFormPageState();
}

class _CreatePostFormPageState extends State<CreatePostFormPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _link = TextEditingController();
  final _target = TextEditingController();
  final _capacity = TextEditingController();
  final _duration = TextEditingController();
  final _steps = TextEditingController();

  @override
  void dispose() {
    for (final c in [_title, _description, _location, _link, _target, _capacity, _duration, _steps]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDateTime({bool withTime = true}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !withTime || !mounted) return date;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    context.read<CreatePostCubit>().submit(
      CreatePostInput(
        title: _title.text,
        description: _description.text,
        location: _location.text,
        link: _link.text,
        target: _target.text,
        capacity: _capacity.text,
        duration: _duration.text,
        steps: _steps.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreatePostCubit, CreatePostState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status.isFailure) context.showMessage(state.error!, error: true);
        if (state.status.isSuccess) {
          context.showMessage('Publicação criada! +30 XP');
          context.go(AppRoutes.home);
          context.push(AppRoutes.post(state.createdPostId!));
        }
      },
      builder: (context, state) {
        final cubit = context.read<CreatePostCubit>();
        final type = state.type;
        return Scaffold(
          appBar: AppBar(title: Text(type == PostType.ad ? 'Criar propaganda' : type.label)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _CoverPicker(type: type, imageUrl: state.imageUrl, onChanged: cubit.setImage),
              const SizedBox(height: 20),
              if (type == PostType.ad) ...[
                _AdPlans(selected: state.adPlan, onSelected: cubit.selectAdPlan),
                const SizedBox(height: 20),
              ],
              AppTextField(label: 'Título', controller: _title),
              const SizedBox(height: 16),
              _Dropdown(
                label: type == PostType.ad ? 'O que deseja divulgar?' : 'Tipo de ${type.label.toLowerCase()}',
                value: state.subtype,
                options: CreatePostCubit.subtypesFor(type),
                onChanged: cubit.selectSubtype,
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Descrição', controller: _description, maxLines: 4),
              const SizedBox(height: 16),
              ..._specificFields(context, state),
              const Text('Categorias', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in PostCategory.values)
                    FilterChip(
                      label: Text(c.label),
                      selected: state.categories.contains(c),
                      onSelected: (_) => cubit.toggleCategory(c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TagInput(tags: state.tags, onChanged: cubit.setTags),
              const SizedBox(height: 32),
              PrimaryButton(label: 'Criar', loading: state.status.isLoading, onPressed: _submit),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _specificFields(BuildContext context, CreatePostState state) {
    final cubit = context.read<CreatePostCubit>();
    Widget dateField(String label, DateTime? value, ValueChanged<DateTime> onPicked, {bool withTime = true}) {
      return AppTextField(
        key: ValueKey('$label$value'),
        label: label,
        readOnly: true,
        initialValue: value == null ? '' : (withTime ? Formatters.shortDateTime(value) : Formatters.date(value)),
        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
        onTap: () async {
          final picked = await _pickDateTime(withTime: withTime);
          if (picked != null) onPicked(picked);
        },
      );
    }

    const gap = SizedBox(height: 16);
    return switch (state.type) {
      PostType.event => [
        Row(
          children: [
            Expanded(child: dateField('Data e hora inicial', state.startsAt, cubit.setStart)),
            const SizedBox(width: 12),
            Expanded(child: dateField('Data e hora final', state.endsAt, cubit.setEnd)),
          ],
        ),
        gap,
        AppTextField(
          label: 'Local',
          controller: _location,
          prefixIcon: const Icon(Icons.place_outlined, size: 18),
          hint: 'Endereço do evento presencial',
        ),
        gap,
        AppTextField(
          label: 'ou Site',
          controller: _link,
          prefixIcon: const Icon(Icons.link_rounded, size: 18),
          hint: 'Link da transmissão online',
        ),
        gap,
      ],
      PostType.donation => [
        AppTextField(
          label: 'Valor (meta)',
          controller: _target,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
          prefixIcon: const Padding(padding: EdgeInsets.all(14), child: Text(r'R$')),
        ),
        gap,
        dateField('Data de encerramento', state.endsAt, cubit.setEnd, withTime: false),
        gap,
        AppTextField(label: 'Local (opcional)', controller: _location),
        gap,
      ],
      PostType.socialAction => [
        dateField('Data (opcional)', state.startsAt, cubit.setStart),
        gap,
        AppTextField(label: 'Local', controller: _location),
        gap,
      ],
      PostType.activity => [
        AppTextField(label: 'Local', controller: _location),
        gap,
        AppTextField(
          label: 'Vagas',
          controller: _capacity,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        gap,
      ],
      PostType.tutorial => [
        AppTextField(
          label: 'Duração (minutos)',
          controller: _duration,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        gap,
        AppTextField(label: 'Passo a passo (um passo por linha)', controller: _steps, maxLines: 5),
        gap,
      ],
      PostType.discussion || PostType.ad => const [],
    };
  }
}

/// Capa da publicação: toque para tirar foto ou escolher da galeria.
class _CoverPicker extends StatelessWidget {
  const _CoverPicker({required this.type, required this.imageUrl, required this.onChanged});

  final PostType type;
  final String? imageUrl;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final result = await showImagePickerSheet(context, title: 'Capa da publicação', canRemove: imageUrl != null);
    switch (result) {
      case ImagePicked(:final reference):
        onChanged(reference);
      case ImageRemoved():
        onChanged(null);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null;
    return Center(
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: hasImage ? double.infinity : 190,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage) PostCover(type: type, imageUrl: imageUrl, height: 160, radius: 12),
              Positioned(
                right: 8,
                bottom: 8,
                child: hasImage
                    ? IconButton.filledTonal(
                        onPressed: () => _pick(context),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Trocar imagem',
                      )
                    : const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.add_photo_alternate_outlined, size: 30, color: AppColors.text),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.label, required this.value, required this.options, required this.onChanged});

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          items: [
            for (final o in options)
              DropdownMenuItem(
                value: o,
                child: Text(o, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ],
    );
  }
}

class _AdPlans extends StatelessWidget {
  const _AdPlans({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Plano', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        for (final MapEntry(key: plan, value: price) in CreatePostCubit.adPlans.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onSelected(plan),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected == plan ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected == plan ? AppColors.primary : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected == plan ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(plan, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      Formatters.currency(price),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
