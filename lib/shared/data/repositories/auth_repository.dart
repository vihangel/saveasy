import '../models/models.dart';

/// Login social disponível.
enum SocialProvider { google, facebook, apple }

/// Resultado do cadastro (passo 1: e-mail e senha).
class SignUpResult {
  const SignUpResult({required this.needsConfirmation, this.user});

  /// true quando o e-mail precisa ser confirmado com o código enviado.
  final bool needsConfirmation;

  /// Já logado (quando o projeto não exige confirmação de e-mail).
  final AppUser? user;
}

/// Dados do "completar perfil" (depois do login).
class ProfileCompletion {
  const ProfileCompletion({
    required this.accountType,
    required this.name,
    required this.username,
    required this.pronouns,
    this.birthDate,
    this.address,
    this.emailNews = false,
    this.avatarUrl,
  });

  final AccountType accountType;
  final String name;
  final String username;
  final String pronouns;
  final DateTime? birthDate;
  final Address? address;
  final bool emailNews;
  final String? avatarUrl;
}

/// Autenticação e conta. Implementações: [MockAuthRepository] (local) e
/// [SupabaseAuthRepository].
abstract interface class AuthRepository {
  bool get hasSeenOnboarding;

  Future<void> markOnboardingSeen();

  Future<AppUser?> restoreSession();

  /// Sessões que chegam "de fora" do fluxo de tela: login social e links de
  /// e-mail. Emite null quando a sessão termina.
  Stream<AppUser?> get sessionChanges;

  Future<AppUser> login(String email, String password);

  /// Login social. Na web o navegador sai do app e a sessão volta por
  /// [sessionChanges]; por isso pode retornar null.
  Future<AppUser?> loginWithProvider(SocialProvider provider);

  Future<void> logout();

  Future<SignUpResult> signUp({required String email, required String password});

  Future<AppUser> verifySignUpCode(String email, String code);

  Future<void> resendSignUpCode(String email);

  Future<bool> isUsernameAvailable(String username);

  Future<AppUser> completeProfile(ProfileCompletion data);

  Future<void> sendRecoveryCode(String email);

  Future<void> verifyRecoveryCode(String email, String code);

  /// Troca a senha depois de validar o código de recuperação.
  Future<void> resetPassword(String email, String newPassword);

  /// Troca a senha estando logado (Configurações).
  Future<void> changePassword(String newPassword);

  /// Exclui a conta e todos os dados (LGPD).
  Future<void> deleteAccount();
}
