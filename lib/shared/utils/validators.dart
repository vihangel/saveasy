abstract final class Validators {
  static String? required(String? value, [String message = 'Campo obrigatório']) =>
      (value == null || value.trim().isEmpty) ? message : null;

  static String? email(String? value) {
    if (required(value) != null) return 'Informe o e-mail';
    final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.[a-zA-Z]{2,}$').hasMatch(value!.trim());
    return ok ? null : 'E-mail inválido';
  }

  /// Senha nova: 8+ caracteres, com letra e número (o Supabase exige 8).
  static String? password(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'A senha precisa ter ao menos 8 caracteres';
    if (v.trim() != v) return 'A senha não pode começar nem terminar com espaço';
    if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Use letras e números na senha';
    }
    return null;
  }

  /// Confirmação de senha: compara com o valor atual do campo de senha.
  static FormFieldValidatorFn confirmPassword(String Function() password) =>
      (value) => (value ?? '').isEmpty ? 'Repita a senha' : (value == password() ? null : 'As senhas não conferem');

  /// @usuário: 3 a 30 caracteres, letras, números, ponto e sublinhado.
  static String? username(String? value) {
    final v = (value ?? '').trim().replaceFirst('@', '');
    if (v.length < 3) return 'Use ao menos 3 caracteres';
    if (v.length > 30) return 'Use no máximo 30 caracteres';
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) return 'Use só letras, números, ponto e _';
    return null;
  }

  /// Link opcional: vazio passa; preenchido precisa ser http(s).
  static String? optionalUrl(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final uri = Uri.tryParse(v.startsWith('http') ? v : 'https://$v');
    final ok = uri != null && uri.host.contains('.') && !v.contains(' ');
    return ok ? null : 'Link inválido';
  }

  /// CPF (11 dígitos) ou CNPJ (14), conferindo os dígitos verificadores.
  static String? cpfCnpj(String? value) {
    final d = (value ?? '').replaceAll(RegExp(r'\D'), '');
    final ok = switch (d.length) {
      11 => _validCpf(d),
      14 => _validCnpj(d),
      _ => false,
    };
    return ok ? null : 'CPF ou CNPJ inválido';
  }

  static bool _validCpf(String d) {
    if (RegExp(r'^(\d)\1+$').hasMatch(d)) return false;
    int digit(int len) {
      var sum = 0;
      for (var i = 0; i < len; i++) {
        sum += int.parse(d[i]) * (len + 1 - i);
      }
      final r = (sum * 10) % 11;
      return r == 10 ? 0 : r;
    }

    return digit(9) == int.parse(d[9]) && digit(10) == int.parse(d[10]);
  }

  static bool _validCnpj(String d) {
    if (RegExp(r'^(\d)\1+$').hasMatch(d)) return false;
    int digit(List<int> weights) {
      var sum = 0;
      for (var i = 0; i < weights.length; i++) {
        sum += int.parse(d[i]) * weights[i];
      }
      final r = sum % 11;
      return r < 2 ? 0 : 11 - r;
    }

    const w1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const w2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    return digit(w1) == int.parse(d[12]) && digit(w2) == int.parse(d[13]);
  }

  static String? cep(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    return digits.length == 8 ? null : 'CEP inválido';
  }

  /// Converte um valor digitado em reais ("1.234,56", "1234.5", "R$ 10") em
  /// número. Retorna null se não for um valor válido.
  static double? parseMoney(String? value) {
    var v = (value ?? '').replaceAll(RegExp(r'[R$\s]'), '');
    if (v.isEmpty) return null;
    if (v.contains(',')) {
      v = v.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(v)) {
      v = v.replaceAll('.', ''); // 1.000 = mil
    }
    return double.tryParse(v);
  }
}

typedef FormFieldValidatorFn = String? Function(String? value);
