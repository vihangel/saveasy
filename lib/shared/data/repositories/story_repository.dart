import '../models/models.dart';

/// Stories de 24h. Implementações: [MockStoryRepository] e
/// [SupabaseStoryRepository].
abstract interface class StoryRepository {
  /// Bandeja do feed (meus, de quem sigo e da minha cidade), mais novos primeiro.
  Future<List<Story>> stories();

  /// Marca como visto. Story de propaganda dá moedas uma vez: nesse caso
  /// retorna o usuário atualizado, senão `null`.
  Future<AppUser?> view(String storyId, {required String userId});

  /// Publica um story e retorna o autor atualizado (o primeiro do dia dá moedas).
  Future<AppUser> create({required AppUser author, required PostType type, required String text, String? imageUrl});

  Future<void> delete(String storyId);
}
