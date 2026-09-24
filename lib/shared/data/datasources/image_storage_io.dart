import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_storage.dart';

Future<String?> documentsPath() async => (await getApplicationDocumentsDirectory()).path;

Future<String> saveImage(XFile file, String? documents) async {
  final folder = Directory(p.join(documents!, 'images'));
  await folder.create(recursive: true);
  final extension = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
  final name = '${DateTime.now().microsecondsSinceEpoch}$extension';
  await File(file.path).copy(p.join(folder.path, name));
  return '${ImageStorage.localPrefix}images/$name';
}

Future<void> deleteImage(String reference, String? documents) async {
  final file = File(p.join(documents!, reference.substring(ImageStorage.localPrefix.length)));
  if (await file.exists()) await file.delete();
}

ImageProvider localImage(String reference, String? documents) =>
    FileImage(File(p.join(documents!, reference.substring(ImageStorage.localPrefix.length))));
