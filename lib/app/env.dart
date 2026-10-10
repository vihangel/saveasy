/// Configuração de ambiente. Pode ser sobrescrita no build:
///
/// ```
/// flutter run --dart-define=BACKEND=mock
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
/// ```
///
/// A chave é a *publishable* (pública por definição): quem protege os dados é
/// a RLS do banco. Nunca colocar a service_role aqui.
abstract final class Env {
  static const backend = String.fromEnvironment('BACKEND', defaultValue: 'supabase');

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mdxwngzxotjembzcywrf.supabase.co',
  );

  static const supabaseKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_EAZgnZelTNKJ_OCmpgrMSA_1XDNOIx0',
  );

  /// Para onde o Supabase manda os links de e-mail (confirmação, senha) na web.
  static const webRedirectUrl = String.fromEnvironment(
    'WEB_REDIRECT_URL',
    defaultValue: 'https://vihangel.github.io/saveasy/',
  );

  static bool get useSupabase => backend == 'supabase';

  /// Botões "Entrar com Google/Facebook". Desligados até os provedores serem
  /// configurados no Supabase (pendência 3). Ligar com --dart-define=SOCIAL_LOGIN=true.
  static const socialLogin = bool.fromEnvironment('SOCIAL_LOGIN');
}
