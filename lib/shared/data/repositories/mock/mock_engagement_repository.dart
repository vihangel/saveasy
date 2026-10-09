import '../../datasources/mock_database.dart';
import '../../models/models.dart';
import '../app_exception.dart';
import '../engagement_repository.dart';

/// Extras de publicação só em memória (modo demo e testes).
class MockEngagementRepository implements EngagementRepository {
  MockEngagementRepository(this._db);

  final MockDatabase _db;
  final _photos = <String, List<PostPhoto>>{};
  final _updates = <String, List<PostUpdate>>{};
  final _requests = <String, List<ItemRequest>>{};
  final _mentions = <String, List<AppUser>>{};
  final _participants = <String, Map<String, ParticipationStatus>>{};

  /// Usuário logado no modo mock (o primeiro com onboarding completo).
  AppUser get _me => _db.users.firstWhere((u) => u.onboardingCompleted);

  @override
  Future<PostExtras> extras(String postId) async {
    final post = _db.posts.where((p) => p.id == postId).firstOrNull;
    return PostExtras(
      photos: _photos[postId] ?? const [],
      updates: _updates[postId] ?? const [],
      mentions: _mentions[postId] ?? const [],
      itemRequests: _requests[postId] ?? const [],
      checkinCode: post?.confirmed ?? false ? 'DEMO42' : null,
    );
  }

  @override
  Future<List<Participant>> participants(String postId) async => [
    for (final e in (_participants[postId] ?? {}).entries) Participant(user: _db.userById(e.key), status: e.value),
  ];

  @override
  Future<List<Participant>> checkIn(String postId, {String? profileId, String? code, bool attended = true}) async {
    final id = profileId ?? (code?.toUpperCase() == 'DEMO42' ? _me.id : null);
    if (id == null) throw const AppException('Código não encontrado neste evento.');
    (_participants[postId] ??= {})[id] = attended ? ParticipationStatus.attended : ParticipationStatus.noShow;
    return participants(postId);
  }

  @override
  Future<List<PostPhoto>> addPhoto(String postId, {required String imageUrl, String caption = ''}) async {
    final photo = PostPhoto(
      id: _db.newId('ph'),
      postId: postId,
      imageUrl: imageUrl,
      caption: caption,
      createdAt: DateTime.now(),
      authorId: _me.id,
      authorName: _me.name,
    );
    return _photos[postId] = [photo, ...?_photos[postId]];
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    for (final key in _photos.keys) {
      _photos[key] = _photos[key]!.where((p) => p.id != photoId).toList();
    }
  }

  @override
  Future<List<PostUpdate>> addUpdate(String postId, {required String body, String? imageUrl}) async {
    if (body.trim().isEmpty) throw const AppException('Escreva a atualização.');
    final update = PostUpdate(id: _db.newId('up'), body: body.trim(), imageUrl: imageUrl, createdAt: DateTime.now());
    return _updates[postId] = [update, ...?_updates[postId]];
  }

  @override
  Future<ItemRequest> requestItem(String postId, {String message = ''}) async {
    final request = ItemRequest(
      id: _db.newId('ir'),
      postId: postId,
      status: ItemRequestStatus.requested,
      requester: _me,
      createdAt: DateTime.now(),
      message: message,
    );
    _requests[postId] = [...?_requests[postId], request];
    return request;
  }

  @override
  Future<ItemRequest> updateItemRequest(String requestId, ItemRequestStatus status) async {
    for (final key in _requests.keys) {
      final list = _requests[key]!;
      final i = list.indexWhere((r) => r.id == requestId);
      if (i >= 0) {
        final updated = list[i].copyWith(status: status);
        _requests[key] = [...list]..[i] = updated;
        return updated;
      }
    }
    throw const AppException('Pedido não encontrado.');
  }

  @override
  Future<List<ItemRequest>> itemRequests(String postId) async => _requests[postId] ?? const [];

  @override
  Future<List<AppUser>> setMentions(String postId, List<String> profileIds) async =>
      _mentions[postId] = [for (final id in profileIds) _db.userById(id)];

  @override
  Future<List<PostPhoto>> album(String profileId) async => [
    for (final list in _photos.values) ...list.where((p) => p.authorId == profileId),
  ];
}
