import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'shared/data/datasources/image_storage.dart';
import 'shared/data/datasources/local_storage.dart';
import 'shared/data/datasources/mock_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Na web, URLs sem '#': /post/123 em vez de /#/post/123.
  usePathUrlStrategy();
  await initializeDateFormatting('pt_BR');

  final storage = await LocalStorage.create();
  final database = MockDatabase(storage);
  await database.load();
  final images = await ImageStorage.create();

  runApp(SaveEasyApp(storage: storage, database: database, images: images));
}
