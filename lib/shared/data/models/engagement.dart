import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_user.dart';
import 'post.dart';

part 'engagement.freezed.dart';
part 'engagement.g.dart';

/// Foto enviada por quem participou de uma ação.
@freezed
abstract class PostPhoto with _$PostPhoto {
  const factory PostPhoto({
    required String id,
    required String postId,
    required String imageUrl,
    required DateTime createdAt,
    @Default('') String caption,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    String? postTitle,
  }) = _PostPhoto;

  factory PostPhoto.fromJson(Map<String, dynamic> json) => _$PostPhotoFromJson(json);
}

/// Novidade publicada pelo autor de uma campanha.
@freezed
abstract class PostUpdate with _$PostUpdate {
  const factory PostUpdate({required String id, required String body, required DateTime createdAt, String? imageUrl}) =
      _PostUpdate;

  factory PostUpdate.fromJson(Map<String, dynamic> json) => _$PostUpdateFromJson(json);
}

enum ItemRequestStatus {
  requested('Aguardando resposta'),
  accepted('Aceito'),
  rejected('Recusado'),
  delivered('Entregue'),
  cancelled('Cancelado');

  const ItemRequestStatus(this.label);

  final String label;
}

/// Pedido para receber um item doado.
@freezed
abstract class ItemRequest with _$ItemRequest {
  const factory ItemRequest({
    required String id,
    required String postId,
    required ItemRequestStatus status,
    required AppUser requester,
    required DateTime createdAt,
    @Default('') String message,
  }) = _ItemRequest;

  factory ItemRequest.fromJson(Map<String, dynamic> json) => _$ItemRequestFromJson(json);
}

/// Pessoa (resumo) mostrada na prévia de participantes.
@freezed
abstract class PersonPreview with _$PersonPreview {
  const factory PersonPreview({required String id, required String name, String? avatarUrl}) = _PersonPreview;

  factory PersonPreview.fromJson(Map<String, dynamic> json) => _$PersonPreviewFromJson(json);
}

/// Extras do detalhe de uma publicação.
@freezed
abstract class PostExtras with _$PostExtras {
  const factory PostExtras({
    @Default(<PostPhoto>[]) List<PostPhoto> photos,
    @Default(<PostUpdate>[]) List<PostUpdate> updates,
    @Default(<AppUser>[]) List<AppUser> mentions,
    @Default(<ItemRequest>[]) List<ItemRequest> itemRequests,
    @Default(<PersonPreview>[]) List<PersonPreview> participantsPreview,

    /// Código que o participante mostra ao organizador no check-in.
    String? checkinCode,
  }) = _PostExtras;

  factory PostExtras.fromJson(Map<String, dynamic> json) => _$PostExtrasFromJson(json);
}

enum ParticipationStatus {
  going('Confirmado'),
  attended('Presente'),
  noShow('Faltou'),
  cancelled('Cancelou');

  const ParticipationStatus(this.label);

  final String label;

  static ParticipationStatus parse(String? value) => switch (value) {
    'attended' => attended,
    'no_show' => noShow,
    'cancelled' => cancelled,
    _ => going,
  };
}

/// Participante na lista do organizador (JSON do perfil + status).
class Participant {
  const Participant({required this.user, required this.status, this.checkedInAt});

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    user: AppUser.fromJson(json),
    status: ParticipationStatus.parse(json['participationStatus'] as String?),
    checkedInAt: json['checkedInAt'] == null ? null : DateTime.parse(json['checkedInAt'] as String),
  );

  final AppUser user;
  final ParticipationStatus status;
  final DateTime? checkedInAt;
}

/// Código de convite e números do usuário logado.
@freezed
abstract class InviteInfo with _$InviteInfo {
  const factory InviteInfo({
    required String code,
    @Default(0) int invited,
    @Default(0) int reachedLevel20,
    AppUser? invitedBy,
    @Default(false) bool canRedeem,
  }) = _InviteInfo;

  factory InviteInfo.fromJson(Map<String, dynamic> json) => _$InviteInfoFromJson(json);
}

enum ResumeKind {
  participation('Participou'),
  attended('Presença confirmada'),
  post('Publicou'),
  donation('Doou'),
  @JsonValue('item_received')
  itemReceived('Recebeu item');

  const ResumeKind(this.label);

  final String label;
}

/// Linha do currículo de ações.
@freezed
abstract class ResumeItem with _$ResumeItem {
  const factory ResumeItem({
    required DateTime date,
    required ResumeKind kind,
    required String title,
    required PostType type,
    String? postId,
    @Default(0) int coins,
    @Default(0) int xp,
  }) = _ResumeItem;

  factory ResumeItem.fromJson(Map<String, dynamic> json) => _$ResumeItemFromJson(json);
}

@freezed
abstract class ActionResume with _$ActionResume {
  const factory ActionResume({
    @Default(<ResumeItem>[]) List<ResumeItem> items,
    @Default(<String, int>{}) Map<String, int> totals,
  }) = _ActionResume;

  factory ActionResume.fromJson(Map<String, dynamic> json) => _$ActionResumeFromJson(json);
}
