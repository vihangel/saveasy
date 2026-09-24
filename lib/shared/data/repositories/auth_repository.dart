import '../datasources/local_storage.dart';
import '../datasources/mock_database.dart';
import '../datasources/mock_seed.dart';
import '../models/models.dart';
import 'app_exception.dart';

/// Dados coletados nos passos do cadastro.
class SignUpData {
  const SignUpData({
    required this.accountType,
    required this.email,
    required this.password,
    required this.name,
    required this.username,
    required this.pronouns,
    required this.birthDate,
    required this.address,
    required this.emailNews,
    this.avatarUrl,
  });

  final AccountType accountType;
  final String email;
  final String password;
  final String name;
  final String username;
  final String pronouns;
  final DateTime? birthDate;
  final Address address;
  final bool emailNews;
  final String? avatarUrl;
}

class AuthRepository {
  AuthRepository(this._db, this._storage);

  final MockDatabase _db;
  final LocalStorage _storage;

  static const _sessionKey = 'session_user_id';
  static const _onboardingKey = 'onboarding_seen';

  final _pendingCodes = <String, String>{};

  bool get hasSeenOnboarding => _storage.readBool(_onboardingKey);

  Future<void> markOnboardingSeen() => _storage.writeBool(_onboardingKey, true);

  Future<AppUser?> restoreSession() async {
    final id = _storage.readString(_sessionKey);
    if (id == null) return null;
    return _db.users.where((u) => u.id == id).firstOrNull;
  }

  Future<AppUser> login(String email, String password) async {
    await _db.delay();
    final credential = _db.credentials.where((c) => c.email.toLowerCase() == email.trim().toLowerCase()).firstOrNull;
    if (credential == null || credential.password != password) {
      throw const AppException('E-mail ou senha inválidos.');
    }
    await _storage.writeString(_sessionKey, credential.userId);
    return _db.userById(credential.userId);
  }

  /// Login social mockado: entra com a conta demo.
  Future<AppUser> loginWithProvider(String provider) => login(MockSeed.demoEmail, MockSeed.demoPassword);

  Future<void> logout() => _storage.writeString(_sessionKey, null);

  Future<bool> emailExists(String email) async {
    await _db.delay();
    return _db.credentials.any((c) => c.email.toLowerCase() == email.trim().toLowerCase());
  }

  Future<bool> usernameExists(String username) async =>
      _db.users.any((u) => u.username.toLowerCase() == username.trim().toLowerCase());

  Future<AppUser> register(SignUpData data) async {
    await _db.delay();
    if (await emailExists(data.email)) {
      throw const AppException('Já existe uma conta com esse e-mail.');
    }
    final user = AppUser(
      id: _db.newId('u'),
      name: data.name.trim(),
      username: data.username.trim().replaceAll('@', ''),
      email: data.email.trim(),
      accountType: data.accountType,
      pronouns: data.pronouns,
      birthDate: data.birthDate,
      address: data.address,
      emailNews: data.emailNews,
      avatarUrl: data.avatarUrl,
      coins: 100,
    );
    _db.users = [..._db.users, user];
    _db.credentials = [..._db.credentials, Credential(email: user.email, password: data.password, userId: user.id)];
    await Future.wait([_db.saveUsers(), _db.saveCredentials()]);
    return user;
  }

  /// Em produção o código iria por e-mail; aqui ele é fixo ([MockSeed.verificationCode]).
  Future<void> sendRecoveryCode(String email) async {
    if (!await emailExists(email)) {
      throw const AppException('Não encontramos uma conta com esse e-mail.');
    }
    _pendingCodes[email.trim().toLowerCase()] = MockSeed.verificationCode;
  }

  Future<void> verifyCode(String email, String code) async {
    await _db.delay();
    if (_pendingCodes[email.trim().toLowerCase()] != code) {
      throw const AppException('Código inválido. Confira o e-mail enviado.');
    }
  }

  Future<void> resetPassword(String email, String newPassword) async {
    await _db.delay();
    final key = email.trim().toLowerCase();
    _db.credentials = [
      for (final c in _db.credentials)
        c.email.toLowerCase() == key ? Credential(email: c.email, password: newPassword, userId: c.userId) : c,
    ];
    _pendingCodes.remove(key);
    await _db.saveCredentials();
  }
}
