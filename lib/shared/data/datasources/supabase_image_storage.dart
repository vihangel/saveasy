import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/app_exception.dart';
import 'image_storage.dart';

/// Envia imagens para o Supabase Storage e devolve a URL pública. O caminho
/// começa pelo id do usuário, que é o que a policy do bucket exige.
class SupabaseImageStorage extends ImageStorage {
  SupabaseImageStorage(this._client) : super.remote();

  final SupabaseClient _client;

  @override
  Future<String> save(XFile file, {ImageBucket bucket = ImageBucket.postCovers}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AppException('Entre na sua conta para enviar imagens.');
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? _mimeFromName(file.name);
    final ext = switch (mime) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.$ext';
    try {
      await _client.storage
          .from(bucket.id)
          .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime, upsert: false));
    } on StorageException {
      throw const AppException('Não foi possível enviar a imagem.');
    }
    return _client.storage.from(bucket.id).getPublicUrl(path);
  }

  @override
  Future<void> delete(String reference) async {
    final marker = '/storage/v1/object/public/';
    final i = reference.indexOf(marker);
    if (i < 0) return;
    final rest = reference.substring(i + marker.length);
    final slash = rest.indexOf('/');
    await _client.storage.from(rest.substring(0, slash)).remove([rest.substring(slash + 1)]);
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
