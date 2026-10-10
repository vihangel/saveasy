import 'package:flutter/services.dart';

import '../../app/env.dart';

Future<void> copyPostLink(String id) => Clipboard.setData(
  ClipboardData(text: Uri.parse(Env.webRedirectUrl).resolve('post/${Uri.encodeComponent(id)}').toString()),
);
