abstract final class Validators {
  static String? required(String? value, [String message = 'Campo obrigatório']) =>
      (value == null || value.trim().isEmpty) ? message : null;

  static String? email(String? value) {
    if (required(value) != null) return 'Informe o e-mail';
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(value!.trim());
    return ok ? null : 'E-mail inválido';
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) return 'A senha precisa ter ao menos 6 caracteres';
    return null;
  }

  static String? cep(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    return digits.length == 8 ? null : 'CEP inválido';
  }
}
