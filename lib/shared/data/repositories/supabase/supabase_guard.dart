import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_exception.dart';

/// Executa uma chamada ao Supabase e converte os erros em [AppException] com
/// mensagem pronta para a tela.
Future<T> supabaseGuard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on AppException {
    rethrow;
  } on AuthException catch (e) {
    throw AppException(_authMessage(e));
  } on PostgrestException catch (e) {
    // Erros de regra (raise exception ... errcode P0001/P0002) já vêm em português.
    if (e.code == 'P0001' || e.code == 'P0002') throw AppException(e.message);
    if (e.code == '42501') throw const AppException('Você não tem permissão para fazer isso.');
    if (e.code == '23505') throw const AppException('Esse registro já existe.');
    throw const AppException('Não foi possível concluir. Tente de novo.');
  } on StorageException catch (_) {
    throw const AppException('Não foi possível enviar a imagem.');
  } on TimeoutException {
    throw const AppException('A conexão demorou demais. Tente de novo.');
  } catch (_) {
    throw const AppException('Sem conexão com o servidor. Verifique sua internet.');
  }
}

String _authMessage(AuthException e) {
  final m = e.message.toLowerCase();
  if (m.contains('invalid login credentials')) return 'E-mail ou senha inválidos.';
  if (m.contains('email not confirmed')) return 'Confirme seu e-mail antes de entrar.';
  if (m.contains('already registered') || m.contains('already exists')) {
    return 'Já existe uma conta com esse e-mail.';
  }
  if (m.contains('expired') || m.contains('invalid') && m.contains('token')) return 'Código inválido ou expirado.';
  if (m.contains('password should be') || m.contains('weak')) {
    return 'Senha fraca. Use ao menos 6 caracteres, com letras e números.';
  }
  if (m.contains('rate limit') || e.statusCode == '429') {
    return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
  }
  if (m.contains('same password') || m.contains('different from the old')) {
    return 'A nova senha precisa ser diferente da atual.';
  }
  return 'Não foi possível autenticar. Tente de novo.';
}
