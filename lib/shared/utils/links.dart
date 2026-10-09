import 'package:url_launcher/url_launcher.dart';

/// Abre um link externo (anúncios, mapas). Retorna false se não conseguir.
Future<bool> openExternalLink(String? url) async {
  if (url == null || url.trim().isEmpty) return false;
  final uri = Uri.tryParse(url.trim().startsWith('http') ? url.trim() : 'https://${url.trim()}');
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
