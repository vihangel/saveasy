import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../../../../app/env.dart';
import '../../datasources/local_storage.dart';
import '../../models/models.dart';
import '../app_exception.dart';
import '../auth_repository.dart';
import 'supabase_guard.dart';

/// Autenticação pelo Supabase Auth. O perfil vem da RPC `my_profile`
/// (mesmo formato do [AppUser]).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, this._storage);

  final SupabaseClient _client;
  final LocalStorage _storage;

  static const _onboardingKey = 'onboarding_seen';

  GoTrueClient get _auth => _client.auth;

  /// Deep link do app mobile para voltar do login social/links de e-mail.
  static const mobileRedirect = 'app.saveeasy://login-callback';

  String? get _redirect => kIsWeb ? Env.webRedirectUrl : mobileRedirect;

  @override
  bool get hasSeenOnboarding => _storage.readBool(_onboardingKey);

  @override
  Future<void> markOnboardingSeen() => _storage.writeBool(_onboardingKey, true);

  /// true entre validar o código de recuperação e trocar a senha: a sessão
  /// temporária não deve logar a pessoa no app.
  bool _recovering = false;

  @override
  Stream<AppUser?> get sessionChanges => _auth.onAuthStateChange
      .where((s) => !_recovering && (s.event == AuthChangeEvent.signedIn || s.event == AuthChangeEvent.signedOut))
      .asyncMap((s) => s.event == AuthChangeEvent.signedOut ? Future<AppUser?>.value() : _myProfileOrNull());

  @override
  Future<AppUser?> restoreSession() async {
    if (_auth.currentSession == null) return null;
    return _myProfileOrNull();
  }

  @override
  Future<AppUser> login(String email, String password) => supabaseGuard(() async {
    await _auth.signInWithPassword(email: email.trim(), password: password);
    return _myProfile();
  });

  @override
  Future<AppUser?> loginWithProvider(SocialProvider provider) => supabaseGuard(() async {
    await _auth.signInWithOAuth(switch (provider) {
      SocialProvider.google => OAuthProvider.google,
      SocialProvider.facebook => OAuthProvider.facebook,
      SocialProvider.apple => OAuthProvider.apple,
    }, redirectTo: _redirect);
    // A sessão chega por [sessionChanges] quando o navegador/app voltar.
    return null;
  });

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<SignUpResult> signUp({required String email, required String password}) => supabaseGuard(() async {
    final res = await _auth.signUp(email: email.trim(), password: password, emailRedirectTo: _redirect);
    // Com confirmação de e-mail ligada, e-mail repetido volta sem identidades.
    if (res.user != null && (res.user!.identities?.isEmpty ?? false)) {
      throw const AppException('Já existe uma conta com esse e-mail.');
    }
    if (res.session != null) return SignUpResult(needsConfirmation: false, user: await _myProfile());
    return const SignUpResult(needsConfirmation: true);
  });

  @override
  Future<AppUser> verifySignUpCode(String email, String code) => supabaseGuard(() async {
    try {
      await _auth.verifyOTP(type: OtpType.email, email: email.trim(), token: code.trim());
    } on AuthException {
      await _auth.verifyOTP(type: OtpType.signup, email: email.trim(), token: code.trim());
    }
    return _myProfile();
  });

  @override
  Future<void> resendSignUpCode(String email) =>
      supabaseGuard(() => _auth.resend(type: OtpType.signup, email: email.trim(), emailRedirectTo: _redirect));

  @override
  Future<bool> isUsernameAvailable(String username) => supabaseGuard(() async {
    final result = await _client.rpc<bool>(
      'is_username_available',
      params: {'p_username': username.trim().replaceAll('@', '')},
    );
    return result;
  });

  @override
  Future<AppUser> completeProfile(ProfileCompletion data) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'complete_profile',
      params: {
        'p_account_type': data.accountType.name,
        'p_name': data.name,
        'p_username': data.username.trim().toLowerCase().replaceAll('@', ''),
        'p_pronouns': data.pronouns,
        'p_birth_date': data.birthDate?.toIso8601String().substring(0, 10),
        'p_cep': data.address?.cep,
        'p_street': data.address?.street,
        'p_complement': data.address?.complement,
        'p_city': data.address?.city,
        'p_state': data.address?.state,
        'p_email_news': data.emailNews,
        'p_avatar_url': data.avatarUrl,
      },
    );
    return AppUser.fromJson(json);
  });

  @override
  Future<void> sendRecoveryCode(String email) =>
      supabaseGuard(() => _auth.resetPasswordForEmail(email.trim(), redirectTo: _redirect));

  @override
  Future<void> verifyRecoveryCode(String email, String code) => supabaseGuard(() async {
    _recovering = true;
    try {
      await _auth.verifyOTP(type: OtpType.recovery, email: email.trim(), token: code.trim());
    } catch (_) {
      _recovering = false;
      rethrow;
    }
  });

  /// Depois do código de recuperação a sessão já está ativa: troca a senha e
  /// sai, para a pessoa entrar de novo com a senha nova.
  @override
  Future<void> resetPassword(String email, String newPassword) => supabaseGuard(() async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
      await _auth.signOut();
    } finally {
      _recovering = false;
    }
  });

  @override
  Future<void> changePassword(String newPassword) =>
      supabaseGuard(() => _auth.updateUser(UserAttributes(password: newPassword)));

  @override
  Future<void> deleteAccount() => supabaseGuard(() async {
    await _client.rpc<void>('delete_my_account');
    await _auth.signOut();
  });

  Future<AppUser> _myProfile() async {
    final json = await _client.rpc<Map<String, dynamic>?>('my_profile');
    if (json == null) throw const AppException('Perfil não encontrado.');
    return AppUser.fromJson(json);
  }

  Future<AppUser?> _myProfileOrNull() async {
    try {
      return await _myProfile();
    } catch (_) {
      return null;
    }
  }
}
