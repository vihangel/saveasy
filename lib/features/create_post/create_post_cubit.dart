import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/notifiers/session_cubit.dart';
import '../../shared/utils/view_status.dart';

part 'create_post_cubit.freezed.dart';
part 'create_post_state.dart';

/// Textos digitados nos formulários de criação.
class CreatePostInput {
  const CreatePostInput({
    required this.title,
    required this.description,
    this.location = '',
    this.link = '',
    this.target = '',
    this.capacity = '',
    this.duration = '',
    this.steps = '',
  });

  final String title;
  final String description;
  final String location;
  final String link;
  final String target;
  final String capacity;
  final String duration;
  final String steps;
}

class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit(PostType type, this._posts, this._session) : super(CreatePostState(type: type));

  final PostRepository _posts;
  final SessionCubit _session;

  /// Opções do campo "Tipo de ..." de cada formulário.
  static List<String> subtypesFor(PostType type) => switch (type) {
    PostType.donation => ['Vaquinha', 'Doação recorrente', 'Itens / alimentos', 'Doação de sangue'],
    PostType.event => ['Presencial', 'Online', 'Híbrido'],
    PostType.socialAction => ['Voluntariado', 'Mutirão', 'Arrecadação', 'Plantio de árvores'],
    PostType.activity => ['Oficina', 'Reciclagem', 'Esporte', 'Cultura'],
    PostType.tutorial => ['Educacional', 'Faça você mesmo', 'Sustentabilidade'],
    PostType.discussion => ['Ideias', 'Dúvidas', 'Debate'],
    PostType.ad => ['Publicação', 'Currículo de boas ações'],
  };

  static const adPlans = {'Diário': 9.90, 'Semanal': 49.90, 'Mensal': 149.90};

  void selectSubtype(String? value) => emit(state.copyWith(subtype: value));

  void setTags(List<String> tags) => emit(state.copyWith(tags: tags));

  void toggleCategory(PostCategory category) => emit(
    state.copyWith(
      categories: state.categories.contains(category)
          ? state.categories.where((c) => c != category).toList()
          : [...state.categories, category],
    ),
  );

  void setStart(DateTime value) => emit(state.copyWith(startsAt: value));

  void setEnd(DateTime value) => emit(state.copyWith(endsAt: value));

  void setImage(String? reference) => emit(state.copyWith(imageUrl: reference));

  void selectAdPlan(String plan) => emit(state.copyWith(adPlan: plan));

  Future<void> submit(CreatePostInput input) async {
    final error = _validate(input);
    if (error != null) return emit(state.copyWith(status: ViewStatus.failure, error: error));

    emit(state.copyWith(status: ViewStatus.loading, error: null));
    final user = _session.user;
    final type = state.type;
    final (post, author) = await _posts.create(
      Post(
        id: '',
        type: type,
        title: input.title.trim(),
        description: input.description.trim(),
        authorId: user.id,
        authorName: user.name,
        authorAvatarUrl: user.avatarUrl,
        imageUrl: state.imageUrl,
        authorType: user.accountType,
        createdAt: DateTime.now(),
        subtype: state.subtype ?? '',
        tags: state.tags,
        categories: state.categories,
        startsAt: state.startsAt,
        endsAt: state.endsAt,
        location: input.location.trim().isEmpty ? null : input.location.trim(),
        link: input.link.trim().isEmpty ? null : input.link.trim(),
        targetAmount: double.tryParse(input.target.replaceAll(',', '.')),
        recurring: state.subtype == 'Doação recorrente',
        capacity: int.tryParse(input.capacity),
        durationMinutes: int.tryParse(input.duration),
        steps: input.steps.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        adPlan: state.adPlan,
        rewardCoins: switch (type) {
          PostType.event => 25,
          PostType.donation => 50,
          PostType.ad => 20,
          _ => 15,
        },
      ),
    );
    _session.updateUser(author);
    emit(state.copyWith(status: ViewStatus.success, createdPostId: post.id));
  }

  String? _validate(CreatePostInput input) {
    if (input.title.trim().isEmpty) return 'Informe o título.';
    if (input.description.trim().isEmpty) return 'Escreva uma descrição.';
    switch (state.type) {
      case PostType.donation:
        if ((double.tryParse(input.target.replaceAll(',', '.')) ?? 0) <= 0) return 'Informe o valor da meta.';
        if (state.endsAt == null && state.subtype != 'Doação recorrente') return 'Informe a data de encerramento.';
      case PostType.event:
        if (state.startsAt == null) return 'Informe a data e hora inicial.';
        if (state.endsAt != null && state.endsAt!.isBefore(state.startsAt!)) {
          return 'A data final precisa ser depois da inicial.';
        }
        if (input.location.trim().isEmpty && input.link.trim().isEmpty) return 'Informe o local ou site.';
      case PostType.activity:
        if (input.location.trim().isEmpty) return 'Informe o local da atividade.';
      case PostType.ad:
        if (state.adPlan == null) return 'Escolha um plano para a propaganda.';
      case PostType.socialAction:
      case PostType.tutorial:
      case PostType.discussion:
        break;
    }
    return null;
  }
}
