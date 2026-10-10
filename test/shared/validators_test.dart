import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/shared/utils/validators.dart';

void main() {
  test('senha exige 8 caracteres, letras e números', () {
    expect(Validators.password('abc12'), isNotNull);
    expect(Validators.password('abcdefgh'), isNotNull);
    expect(Validators.password('12345678'), isNotNull);
    expect(Validators.password(' abcd1234'), isNotNull);
    expect(Validators.password('abcd1234'), isNull);
  });

  test('confirmação de senha', () {
    final confirm = Validators.confirmPassword(() => 'abcd1234');
    expect(confirm(''), 'Repita a senha');
    expect(confirm('abcd123'), isNotNull);
    expect(confirm('abcd1234'), isNull);
  });

  test('e-mail', () {
    expect(Validators.email('maria@exemplo.com.br'), isNull);
    expect(Validators.email('maria@exemplo'), isNotNull);
    expect(Validators.email(''), isNotNull);
  });

  test('nome de usuário', () {
    expect(Validators.username('ma'), isNotNull);
    expect(Validators.username('maria silva'), isNotNull);
    expect(Validators.username('@maria.cuiaba_1'), isNull);
  });

  test('valor em reais', () {
    expect(Validators.parseMoney('1.234,56'), 1234.56);
    expect(Validators.parseMoney('10,5'), 10.5);
    expect(Validators.parseMoney('1.000'), 1000);
    expect(Validators.parseMoney('12.5'), 12.5);
    expect(Validators.parseMoney(r'R$ 50'), 50);
    expect(Validators.parseMoney(''), isNull);
    expect(Validators.parseMoney('abc'), isNull);
  });

  test('CPF e CNPJ com dígitos verificadores', () {
    expect(Validators.cpfCnpj('529.982.247-25'), isNull);
    expect(Validators.cpfCnpj('52998224724'), isNotNull);
    expect(Validators.cpfCnpj('11111111111'), isNotNull);
    expect(Validators.cpfCnpj('11.222.333/0001-81'), isNull);
    expect(Validators.cpfCnpj('11222333000180'), isNotNull);
    expect(Validators.cpfCnpj('123'), isNotNull);
  });

  test('link opcional', () {
    expect(Validators.optionalUrl(''), isNull);
    expect(Validators.optionalUrl('saveeasy.com.br/evento'), isNull);
    expect(Validators.optionalUrl('https://meet.google.com/abc'), isNull);
    expect(Validators.optionalUrl('não é link'), isNotNull);
  });
}
