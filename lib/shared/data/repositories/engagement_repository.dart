import '../models/models.dart';

/// Participantes, check-in, fotos, atualizações de campanha, doação de itens
/// e pessoas marcadas. Implementações: [MockEngagementRepository] e
/// [SupabaseEngagementRepository].
abstract interface class EngagementRepository {
  Future<PostExtras> extras(String postId);

  Future<List<Participant>> participants(String postId);

  /// Organizador marca presença por pessoa ou pelo código do participante.
  Future<List<Participant>> checkIn(String postId, {String? profileId, String? code, bool attended = true});

  Future<List<PostPhoto>> addPhoto(String postId, {required String imageUrl, String caption = ''});

  Future<void> deletePhoto(String photoId);

  Future<List<PostUpdate>> addUpdate(String postId, {required String body, String? imageUrl});

  Future<ItemRequest> requestItem(String postId, {String message = ''});

  Future<ItemRequest> updateItemRequest(String requestId, ItemRequestStatus status);

  Future<List<ItemRequest>> itemRequests(String postId);

  Future<List<AppUser>> setMentions(String postId, List<String> profileIds);

  /// Fotos enviadas pela pessoa (álbum do perfil).
  Future<List<PostPhoto>> album(String profileId);
}
