import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../shared/data/datasources/image_storage.dart';
import '../shared/data/datasources/local_storage.dart';
import '../shared/data/datasources/mock_database.dart';
import '../shared/data/repositories/repositories.dart';
import '../shared/notifiers/session_cubit.dart';
import '../shared/services/media_picker_service.dart';
import 'responsive_frame.dart';
import 'router.dart';
import 'theme.dart';

class SaveEasyApp extends StatefulWidget {
  const SaveEasyApp({super.key, required this.storage, required this.database, required this.images, this.mediaPicker});

  final LocalStorage storage;
  final MockDatabase database;
  final ImageStorage images;

  /// Permite injetar um seletor falso nos testes.
  final MediaPickerService? mediaPicker;

  @override
  State<SaveEasyApp> createState() => _SaveEasyAppState();
}

class _SaveEasyAppState extends State<SaveEasyApp> {
  late final _authRepository = AuthRepository(widget.database, widget.storage);
  late final _session = SessionCubit(_authRepository);
  late final GoRouter _router = createRouter(_session);

  @override
  void dispose() {
    _session.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = widget.database;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: widget.images),
        RepositoryProvider(create: (_) => widget.mediaPicker ?? MediaPickerService()),
        RepositoryProvider(create: (_) => UserRepository(db)),
        RepositoryProvider(create: (_) => PostRepository(db)),
        RepositoryProvider(create: (_) => WalletRepository(db)),
        RepositoryProvider(create: (_) => GamificationRepository(db)),
        RepositoryProvider(create: (_) => StoreRepository(db)),
        RepositoryProvider(create: (_) => StoryRepository(db)),
        RepositoryProvider(create: (_) => ChatRepository(db)),
        RepositoryProvider(create: (_) => NotificationRepository(db)),
      ],
      child: BlocProvider.value(
        value: _session,
        child: MaterialApp.router(
          title: 'Save Easy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
          scrollBehavior: const AppScrollBehavior(),
          builder: (context, child) => ResponsiveFrame(child: child!),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    );
  }
}
