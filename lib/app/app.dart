import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../shared/notifiers/session_cubit.dart';
import 'dependencies.dart';
import 'responsive_frame.dart';
import 'router.dart';
import 'theme.dart';

class SaveEasyApp extends StatefulWidget {
  const SaveEasyApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<SaveEasyApp> createState() => _SaveEasyAppState();
}

class _SaveEasyAppState extends State<SaveEasyApp> {
  late final _session = SessionCubit(widget.deps.auth);
  late final GoRouter _router = createRouter(_session);
  StreamSubscription<SessionState>? _mirror;

  @override
  void initState() {
    super.initState();
    if (widget.deps.mirrorSession) {
      _mirror = _session.stream.listen((state) {
        final user = state.userOrNull;
        if (user != null) widget.deps.database.mirrorUser(user);
      });
    }
  }

  @override
  void dispose() {
    _mirror?.cancel();
    _session.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.deps;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: deps.auth),
        RepositoryProvider.value(value: deps.images),
        RepositoryProvider.value(value: deps.mediaPicker),
        RepositoryProvider.value(value: deps.users),
        RepositoryProvider.value(value: deps.posts),
        RepositoryProvider.value(value: deps.wallet),
        RepositoryProvider.value(value: deps.gamification),
        RepositoryProvider.value(value: deps.store),
        RepositoryProvider.value(value: deps.engagement),
        RepositoryProvider.value(value: deps.ads),
        RepositoryProvider.value(value: deps.stories),
        RepositoryProvider.value(value: deps.chat),
        RepositoryProvider.value(value: deps.notifications),
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
