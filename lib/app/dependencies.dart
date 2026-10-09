import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../shared/data/datasources/image_storage.dart';
import '../shared/data/datasources/local_storage.dart';
import '../shared/data/datasources/mock_database.dart';
import '../shared/data/datasources/supabase_image_storage.dart';
import '../shared/data/repositories/repositories.dart';
import '../shared/services/media_picker_service.dart';

/// Monta os repositórios do app. Hoje o Supabase cobre conta, perfil,
/// publicações, interações, participação, envio de moedas, stories, chat e
/// notificações; o restante (loja, recompensas, dinheiro em R$) ainda usa o
/// banco mock, que espelha o usuário logado ([mirrorSession]).
class AppDependencies {
  AppDependencies({
    required this.auth,
    required this.users,
    required this.posts,
    required this.wallet,
    required this.gamification,
    required this.engagement,
    required this.store,
    required this.stories,
    required this.chat,
    required this.notifications,
    required this.images,
    required this.mediaPicker,
    required this.database,
    this.mirrorSession = false,
  });

  /// Tudo local (testes e `--dart-define=BACKEND=mock`).
  factory AppDependencies.mock(
    MockDatabase db,
    LocalStorage storage, {
    required ImageStorage images,
    MediaPickerService? mediaPicker,
  }) => AppDependencies(
    auth: MockAuthRepository(db, storage),
    users: MockUserRepository(db),
    posts: MockPostRepository(db),
    wallet: WalletRepository(db),
    gamification: MockGamificationRepository(db),
    engagement: MockEngagementRepository(db),
    store: StoreRepository(db),
    stories: MockStoryRepository(db),
    chat: MockChatRepository(db),
    notifications: MockNotificationRepository(db),
    images: images,
    mediaPicker: mediaPicker ?? MediaPickerService(),
    database: db,
  );

  factory AppDependencies.supabase(SupabaseClient client, MockDatabase db, LocalStorage storage) => AppDependencies(
    auth: SupabaseAuthRepository(client, storage),
    users: SupabaseUserRepository(client),
    posts: SupabasePostRepository(client),
    wallet: SupabaseWalletRepository(client, db),
    gamification: SupabaseGamificationRepository(client),
    engagement: SupabaseEngagementRepository(client),
    store: StoreRepository(db),
    stories: SupabaseStoryRepository(client),
    chat: SupabaseChatRepository(client),
    notifications: SupabaseNotificationRepository(client),
    images: SupabaseImageStorage(client),
    mediaPicker: MediaPickerService(),
    database: db,
    mirrorSession: true,
  );

  final AuthRepository auth;
  final UserRepository users;
  final PostRepository posts;
  final WalletRepository wallet;
  final GamificationRepository gamification;
  final EngagementRepository engagement;
  final StoreRepository store;
  final StoryRepository stories;
  final ChatRepository chat;
  final NotificationRepository notifications;
  final ImageStorage images;
  final MediaPickerService mediaPicker;
  final MockDatabase database;

  /// Copia o usuário logado para o banco mock (telas que ainda não migraram).
  final bool mirrorSession;
}
