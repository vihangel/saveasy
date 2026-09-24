import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/achievements/achievements_page.dart';
import '../features/auth/forgot_password/forgot_password_cubit.dart';
import '../features/auth/forgot_password/forgot_password_pages.dart';
import '../features/auth/login/login_cubit.dart';
import '../features/auth/login/login_page.dart';
import '../features/auth/sign_up/sign_up_cubit.dart';
import '../features/auth/sign_up/sign_up_pages.dart';
import '../features/chat/chat_page.dart';
import '../features/community_subscription/community_subscription_page.dart';
import '../features/create_post/ad_info_page.dart';
import '../features/create_post/create_post_form_page.dart';
import '../features/create_post/create_post_type_page.dart';
import '../features/donate/donate_page.dart';
import '../features/edit_profile/edit_profile_page.dart';
import '../features/event_confirmed/event_confirmed_page.dart';
import '../features/feed/feed_page.dart';
import '../features/home/home_shell.dart';
import '../features/messages/messages_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/onboarding/welcome_page.dart';
import '../features/post_detail/post_detail_page.dart';
import '../features/profile/profile_page.dart';
import '../features/rewards/rewards_cubit.dart';
import '../features/rewards/rewards_page.dart';
import '../features/send_coins/send_coins_page.dart';
import '../features/splash/splash_page.dart';
import '../features/stories/new_story_page.dart';
import '../features/stories/stories_page.dart';
import '../features/store/store_cubit.dart';
import '../features/store/store_page.dart';
import '../features/wallet/friend_picker_page.dart';
import '../features/wallet/wallet_page.dart';
import '../shared/data/models/models.dart';
import '../shared/data/repositories/repositories.dart';
import '../shared/notifiers/session_cubit.dart';
import 'routes.dart';

GoRouter createRouter(SessionCubit session) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _StreamListenable(session.stream),
    redirect: (context, state) => _redirect(session.state, state),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomePage()),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => BlocProvider(
          create: (context) => LoginCubit(context.read<AuthRepository>(), context.read<SessionCubit>()),
          child: const LoginPage(),
        ),
      ),

      // Recuperar senha: um cubit compartilhado pelas três telas.
      ShellRoute(
        builder: (context, _, child) =>
            BlocProvider(create: (context) => ForgotPasswordCubit(context.read<AuthRepository>()), child: child),
        routes: [
          GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordPage()),
          GoRoute(path: AppRoutes.forgotCode, builder: (_, _) => const VerifyCodePage()),
          GoRoute(path: AppRoutes.resetPassword, builder: (_, _) => const ResetPasswordPage()),
        ],
      ),

      // Cadastro: um cubit acumula os dados dos passos.
      ShellRoute(
        builder: (context, _, child) =>
            BlocProvider(create: (context) => SignUpCubit(context.read<AuthRepository>()), child: child),
        routes: [
          GoRoute(path: AppRoutes.signUp, builder: (_, _) => const AccountTypePage()),
          GoRoute(path: AppRoutes.signUpCredentials, builder: (_, _) => const SignUpCredentialsPage()),
          GoRoute(path: AppRoutes.signUpProfile, builder: (_, _) => const SignUpProfilePage()),
          GoRoute(path: AppRoutes.signUpAddress, builder: (_, _) => const SignUpAddressPage()),
          GoRoute(path: AppRoutes.signUpSuccess, builder: (_, _) => const SignUpSuccessPage()),
        ],
      ),

      // App logado com barra inferior.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, _) => BlocProvider(create: createFeedCubit, child: const FeedPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.messages, builder: (context, _) => MessagesPage.route(context))],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.notifications, builder: (context, _) => NotificationsPage.route(context))],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, _) => ProfilePage.route(context, context.read<SessionCubit>().user.id),
              ),
            ],
          ),
        ],
      ),

      // Telas empilhadas por cima da barra inferior.
      GoRoute(path: AppRoutes.create, builder: (_, _) => const CreatePostTypePage()),
      GoRoute(path: AppRoutes.adInfo, builder: (_, _) => const AdInfoPage()),
      GoRoute(
        path: '/create/:type',
        builder: (context, state) =>
            CreatePostFormPage.route(context, PostType.values.byName(state.pathParameters['type']!)),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) => PostDetailPage.route(context, state.pathParameters['id']!),
        routes: [
          GoRoute(path: 'donate', builder: (context, state) => DonatePage.route(context, state.pathParameters['id']!)),
          GoRoute(
            path: 'confirmed',
            builder: (_, state) => EventConfirmedPage(postId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.newStory, builder: (_, _) => const NewStoryPage()),
      GoRoute(
        path: '/stories/:index',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: StoriesPage.route(context, int.parse(state.pathParameters['index']!)),
        ),
      ),
      GoRoute(path: AppRoutes.editProfile, builder: (context, _) => EditProfilePage.route(context)),
      GoRoute(
        path: '/users/:id',
        builder: (context, state) => ProfilePage.route(context, state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'subscribe',
            builder: (context, state) => CommunitySubscriptionPage.route(context, state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'send-coins',
            builder: (context, state) =>
                SendCoinsPage.route(context, state.pathParameters['id']!, state.uri.queryParameters['post']),
          ),
        ],
      ),
      GoRoute(
        path: '/messages/:threadId',
        builder: (context, state) => ChatPage.route(context, state.pathParameters['threadId']!),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, _) => WalletPage.route(context),
        routes: [GoRoute(path: 'send', builder: (_, _) => const FriendPickerPage())],
      ),
      GoRoute(path: AppRoutes.achievements, builder: (context, _) => AchievementsPage.route(context)),

      // Lista e detalhe compartilham o mesmo cubit.
      ShellRoute(
        builder: (context, _, child) => BlocProvider(
          create: (context) =>
              RewardsCubit(context.read<GamificationRepository>(), context.read<SessionCubit>())..load(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.rewards,
            builder: (_, _) => const RewardsPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => RewardDetailPage(rewardId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      ShellRoute(
        builder: (context, _, child) => BlocProvider(
          create: (context) => StoreCubit(
            context.read<StoreRepository>(),
            context.read<WalletRepository>(),
            context.read<SessionCubit>(),
          )..load(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.store,
            builder: (_, _) => const StorePage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ProductPage(productId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

const _publicRoutes = {AppRoutes.welcome, AppRoutes.login};
const _publicPrefixes = [AppRoutes.forgotPassword, AppRoutes.signUp];

String? _redirect(SessionState session, GoRouterState state) {
  final location = state.matchedLocation;
  final isPublic = _publicRoutes.contains(location) || _publicPrefixes.any(location.startsWith);
  // Link aberto antes da sessão ser restaurada: guarda para voltar depois da splash.
  final pending = state.uri.queryParameters['from'];
  return switch (session) {
    SessionUnknown() when location != AppRoutes.splash => Uri(
      path: AppRoutes.splash,
      queryParameters: {'from': state.uri.toString()},
    ).toString(),
    SessionUnknown() => null,
    SessionUnauthenticated(:final onboardingSeen) when !isPublic =>
      onboardingSeen ? (pending != null && _isPublicPath(pending) ? pending : AppRoutes.login) : AppRoutes.welcome,
    SessionUnauthenticated(:final onboardingSeen) when location == AppRoutes.welcome && onboardingSeen =>
      AppRoutes.login,
    SessionAuthenticated() when location == AppRoutes.splash =>
      pending != null && !_isPublicPath(pending) ? pending : AppRoutes.home,
    SessionAuthenticated() when isPublic => AppRoutes.home,
    _ => null,
  };
}

bool _isPublicPath(String path) {
  final location = Uri.parse(path).path;
  return _publicRoutes.contains(location) || _publicPrefixes.any(location.startsWith);
}

/// Faz o go_router reavaliar o redirect quando a sessão muda.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
