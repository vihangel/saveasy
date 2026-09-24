import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'image_storage_io.dart' if (dart.library.js_interop) 'image_storage_web.dart' as platform;

/// Guarda as imagens escolhidas pelo usuário e devolve uma referência em
/// texto para salvar nos modelos (`AppUser.avatarUrl`, `Post.imageUrl`...).
///
/// - Mobile/desktop: copia o arquivo para a pasta de documentos do app e
///   devolve `local:images/<nome>` (caminho relativo, porque no iOS o caminho
///   absoluto do container muda a cada atualização do app).
/// - Web: devolve um data URI (`data:image/jpeg;base64,...`).
///
/// Quando existir back-end, basta trocar por um upload que devolva a URL.
class ImageStorage {
  ImageStorage._(this._documentsPath);

  final String? _documentsPath;
  final _memoryCache = <String, Uint8List>{};

  static const localPrefix = 'local:';

  static Future<ImageStorage> create() async => ImageStorage._(await platform.documentsPath());

  /// Instância sem pasta de documentos, para testes.
  @visibleForTesting
  factory ImageStorage.forTesting([String? documentsPath]) => ImageStorage._(documentsPath);

  Future<String> save(XFile file) => platform.saveImage(file, _documentsPath);

  Future<void> delete(String reference) async {
    if (reference.startsWith(localPrefix)) await platform.deleteImage(reference, _documentsPath);
  }

  /// Converte uma referência salva em algo que o widget [Image] consegue desenhar.
  ImageProvider? provider(String? reference) {
    if (reference == null || reference.isEmpty) return null;
    if (reference.startsWith('data:')) {
      final bytes = _memoryCache.putIfAbsent(reference, () => UriData.parse(reference).contentAsBytes());
      return MemoryImage(bytes);
    }
    if (reference.startsWith(localPrefix)) return platform.localImage(reference, _documentsPath);
    if (reference.startsWith('http')) return NetworkImage(reference);
    return null;
  }

  /// Usado pela web: transforma os bytes lidos em data URI.
  static String toDataUri(Uint8List bytes, String? mimeType) =>
      'data:${mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
}
