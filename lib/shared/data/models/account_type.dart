import 'package:json_annotation/json_annotation.dart';

enum AccountType {
  @JsonValue('personal')
  personal(
    'Pessoal',
    'Esta é a opção ideal se você está interessado em ver as ações de outras pessoas, ajudar ou criar vaquinhas.',
  ),
  @JsonValue('business')
  business(
    'Empresarial',
    'Se você é uma empresa que deseja compartilhar suas boas ações, essa é a escolha certa para você.',
  ),
  @JsonValue('influencer')
  influencer(
    'Influenciador',
    'Se você tem muitos seguidores e deseja usar sua influência para doações, essa é a opção perfeita.',
  ),
  @JsonValue('community')
  community(
    'Comunidade',
    'Se você representa uma organização sem fins lucrativos ou um projeto que precisa de divulgação e apoio, escolha esta opção.',
  );

  const AccountType(this.label, this.description);

  final String label;
  final String description;
}
