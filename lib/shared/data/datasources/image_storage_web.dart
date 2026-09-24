import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'image_storage.dart';

Future<String?> documentsPath() async => null;

/// Na web não há sistema de arquivos: a imagem vira um data URI e fica no
/// localStorage junto com os outros dados mockados.
Future<String> saveImage(XFile file, String? documents) async =>
    ImageStorage.toDataUri(await file.readAsBytes(), file.mimeType);

Future<void> deleteImage(String reference, String? documents) async {}

ImageProvider? localImage(String reference, String? documents) => null;
