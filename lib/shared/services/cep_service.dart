import 'dart:convert';

import 'package:http/http.dart' as http;

/// Endereço retornado pela busca de CEP.
class CepResult {
  const CepResult({required this.street, required this.neighborhood, required this.city, required this.state});

  final String street;
  final String neighborhood;
  final String city;
  final String state;
}

/// Busca de CEP pela API pública do ViaCEP (sem chave).
class CepService {
  CepService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Retorna null se o CEP não existir ou a busca falhar (o usuário digita).
  Future<CepResult?> lookup(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    try {
      final res = await _client
          .get(Uri.parse('https://viacep.com.br/ws/$digits/json/'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['erro'] != null) return null;
      return CepResult(
        street: json['logradouro'] as String? ?? '',
        neighborhood: json['bairro'] as String? ?? '',
        city: json['localidade'] as String? ?? '',
        state: json['uf'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
