import '../../datasources/local_storage.dart';
import '../../datasources/mock_database.dart';
import '../../datasources/mock_seed.dart';
import '../../models/models.dart';
import '../app_exception.dart';
import '../auth_repository.dart';

/// Autenticação local (sem back-end). O código de e-mail é sempre
/// [MockSeed.verificationCode].
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._db, this._storage);

  final MockDatabase _db;
  final LocalStorage _storage;

  static const _sessionKey = 'session_user_id';
  static const _onboardingKey = 'onboarding_seen';

  final _pendingCodes = <String, String>{};

  @override
  bool get hasSeenOnboarding => _storage.readBool(_onboardingKey);

  @override
  Future<void> markOnboardingSeen() => _storage.writeBool(_onboardingKey, true);

  @override
  Stream<AppUser?> get sessionChanges => const Stream.empty();

  @override
  Future<AppUser?> restoreSession() async {
    final id = _storage.readString(_sessionKey);
    if (id == null) return null;
    return _db.users.where((u) => u.id == id).firstOrNull;
  }

  @override
  Future<AppUser> login(String email, String password) async {
    await _db.delay();
    final credential = _credential(email);
    if (credential == null || credential.password != password) {
      throw const AppException('E-mail ou senha inválidos.');
    }
    await _storage.writeString(_sessionKey, credential.userId);
    return _db.userById(credential.userId);
  }

  /// Login social mockado: entra com a conta demo.
  @override
  Future<AppUser?> loginWithProvider(SocialProvider provider) => login(MockSeed.demoEmail, MockSeed.demoPassword);

  @override
  Future<void> logout() => _storage.writeString(_sessionKey, null);

  @override
  Future<SignUpResult> signUp({required String email, required String password}) async {
    await _db.delay();
    if (_credential(email) != null) throw const AppException('Já existe uma conta com esse e-mail.');
    final user = AppUser(
      id: _db.newId('u'),
      name: '',
      username: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      accountType: AccountType.personal,
      coins: 100,
      onboardingCompleted: false,
    );
    _db.users = [..._db.users, user];
    _db.credentials = [..._db.credentials, Credential(email: user.email, password: password, userId: user.id)];
    await Future.wait([_db.saveUsers(), _db.saveCredentials()]);
    _pendingCodes[_key(email)] = MockSeed.verificationCode;
    return const SignUpResult(needsConfirmation: true);
  }

  @override
  Future<AppUser> verifySignUpCode(String email, String code) async {
    await _db.delay();
    if (_pendingCodes[_key(email)] != code) throw const AppException('Código inválido ou expirado.');
    _pendingCodes.remove(_key(email));
    final credential = _credential(email)!;
    await _storage.writeString(_sessionKey, credential.userId);
    return _db.userById(credential.userId);
  }

  @override
  Future<void> resendSignUpCode(String email) async => _pendingCodes[_key(email)] = MockSeed.verificationCode;

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final me = _storage.readString(_sessionKey);
    final u = username.trim().toLowerCase().replaceAll('@', '');
    return RegExp(r'^[a-z0-9._]{3,30}$').hasMatch(u) &&
        !_db.users.any((x) => x.username.toLowerCase() == u && x.id != me);
  }

  @override
  Future<AppUser> completeProfile(ProfileCompletion data) async {
    await _db.delay();
    if (!await isUsernameAvailable(data.username)) {
      throw const AppException('Esse nome de usuário já está em uso.');
    }
    final me = _db.userById(_storage.readString(_sessionKey)!);
    final updated = me.copyWith(
      accountType: data.accountType,
      name: data.name.trim(),
      username: data.username.trim().toLowerCase().replaceAll('@', ''),
      pronouns: data.pronouns,
      birthDate: data.birthDate,
      address: data.address,
      city: data.address?.city,
      state: data.address?.state,
      emailNews: data.emailNews,
      avatarUrl: data.avatarUrl ?? me.avatarUrl,
      onboardingCompleted: true,
    );
    await _db.replaceUser(updated);
    return updated;
  }

  @override
  Future<void> sendRecoveryCode(String email) async {
    if (_credential(email) == null) throw const AppException('Não encontramos uma conta com esse e-mail.');
    _pendingCodes[_key(email)] = MockSeed.verificationCode;
  }

  @override
  Future<void> verifyRecoveryCode(String email, String code) async {
    await _db.delay();
    if (_pendingCodes[_key(email)] != code) throw const AppException('Código inválido ou expirado.');
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    await _db.delay();
    final key = _key(email);
    _db.credentials = [
      for (final c in _db.credentials)
        c.email.toLowerCase() == key ? Credential(email: c.email, password: newPassword, userId: c.userId) : c,
    ];
    _pendingCodes.remove(key);
    await _db.saveCredentials();
  }

  @override
  Future<void> changePassword(String newPassword) async {
    final id = _storage.readString(_sessionKey);
    final credential = _db.credentials.firstWhere((c) => c.userId == id);
    await resetPassword(credential.email, newPassword);
  }

  @override
  Future<void> deleteAccount() async {
    final id = _storage.readString(_sessionKey);
    _db.users = _db.users.where((u) => u.id != id).toList();
    _db.credentials = _db.credentials.where((c) => c.userId != id).toList();
    await Future.wait([_db.saveUsers(), _db.saveCredentials(), logout()]);
  }

  String _key(String email) => email.trim().toLowerCase();

  Credential? _credential(String email) =>
      _db.credentials.where((c) => c.email.toLowerCase() == _key(email)).firstOrNull;
}
