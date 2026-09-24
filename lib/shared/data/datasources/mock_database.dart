import '../models/models.dart';
import 'local_storage.dart';
import 'mock_seed.dart';

/// Credenciais ficam separadas do perfil (como estariam num backend).
class Credential {
  const Credential({required this.email, required this.password, required this.userId});

  factory Credential.fromJson(Map<String, dynamic> json) => Credential(
    email: json['email'] as String,
    password: json['password'] as String,
    userId: json['userId'] as String,
  );

  final String email;
  final String password;
  final String userId;

  Map<String, dynamic> toJson() => {'email': email, 'password': password, 'userId': userId};
}

/// "Banco" em memória que substitui a API enquanto ela não existe.
///
/// Na primeira execução carrega o [MockSeed]; depois disso tudo o que for
/// alterado é salvo no [LocalStorage], então os dados sobrevivem ao reinício.
class MockDatabase {
  MockDatabase(this._storage);

  final LocalStorage _storage;

  static const latency = Duration(milliseconds: 350);

  late List<Credential> credentials;
  late List<AppUser> users;
  late List<Post> posts;
  late List<Comment> comments;
  late List<Story> stories;
  late List<Reward> rewards;
  late List<Achievement> achievements;
  late List<Product> products;
  late List<WalletTransaction> transactions;
  late List<ChatThread> chats;
  late List<ChatMessage> messages;
  late List<AppNotification> notifications;

  Future<void> load() async {
    credentials = _read('credentials', MockSeed.credentials, Credential.fromJson);
    users = _read('users', MockSeed.users, AppUser.fromJson);
    posts = _read('posts', MockSeed.posts, Post.fromJson);
    comments = _read('comments', MockSeed.comments, Comment.fromJson);
    stories = _read('stories', MockSeed.stories, Story.fromJson);
    rewards = _read('rewards', MockSeed.rewards, Reward.fromJson);
    achievements = _read('achievements', MockSeed.achievements, Achievement.fromJson);
    products = _read('products', MockSeed.products, Product.fromJson);
    transactions = _read('transactions', MockSeed.transactions, WalletTransaction.fromJson);
    chats = _read('chats', MockSeed.chats, ChatThread.fromJson);
    messages = _read('messages', MockSeed.messages, ChatMessage.fromJson);
    notifications = _read('notifications', MockSeed.notifications, AppNotification.fromJson);
  }

  List<T> _read<T>(String key, List<Map<String, dynamic>> Function() seed, T Function(Map<String, dynamic>) fromJson) =>
      (_storage.readList(key) ?? seed()).map(fromJson).toList();

  /// Simula o tempo de resposta de uma API.
  Future<void> delay() => Future<void>.delayed(latency);

  Future<void> saveCredentials() => _write('credentials', credentials.map((e) => e.toJson()));
  Future<void> saveUsers() => _write('users', users.map((e) => e.toJson()));
  Future<void> savePosts() => _write('posts', posts.map((e) => e.toJson()));
  Future<void> saveComments() => _write('comments', comments.map((e) => e.toJson()));
  Future<void> saveStories() => _write('stories', stories.map((e) => e.toJson()));
  Future<void> saveRewards() => _write('rewards', rewards.map((e) => e.toJson()));
  Future<void> saveAchievements() => _write('achievements', achievements.map((e) => e.toJson()));
  Future<void> saveTransactions() => _write('transactions', transactions.map((e) => e.toJson()));
  Future<void> saveChats() => _write('chats', chats.map((e) => e.toJson()));
  Future<void> saveMessages() => _write('messages', messages.map((e) => e.toJson()));
  Future<void> saveNotifications() => _write('notifications', notifications.map((e) => e.toJson()));

  Future<void> _write(String key, Iterable<Map<String, dynamic>> items) => _storage.writeList(key, items.toList());

  String newId(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  AppUser userById(String id) => users.firstWhere((u) => u.id == id);

  Future<void> replaceUser(AppUser user) async {
    users = [for (final u in users) u.id == user.id ? user : u];
    await saveUsers();
  }

  Future<void> replacePost(Post post) async {
    posts = [for (final p in posts) p.id == post.id ? post : p];
    await savePosts();
  }
}
