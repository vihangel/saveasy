/// Caminhos de navegação do app (usados com go_router).
abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';

  static const forgotPassword = '/forgot-password';
  static const forgotCode = '/forgot-password/code';
  static const resetPassword = '/forgot-password/reset';

  static const signUp = '/signup';
  static const signUpCredentials = '/signup/credentials';
  static const signUpProfile = '/signup/profile';
  static const signUpAddress = '/signup/address';
  static const signUpSuccess = '/signup/success';

  static const home = '/home';
  static const messages = '/messages';
  static const notifications = '/notifications';
  static const profile = '/profile';

  static const create = '/create';
  static String createForm(String type) => '/create/$type';
  static const adInfo = '/create/ad-info';

  static String post(String id) => '/post/$id';
  static String donate(String postId) => '/post/$postId/donate';
  static String eventConfirmed(String postId) => '/post/$postId/confirmed';

  static String stories(int index) => '/stories/$index';
  static const newStory = '/stories/new';

  static String user(String id) => '/users/$id';
  static String subscribe(String communityId) => '/users/$communityId/subscribe';
  static String sendCoins(String userId, {String? postId}) =>
      '/users/$userId/send-coins${postId == null ? '' : '?post=$postId'}';
  static const editProfile = '/profile/edit';

  static String chat(String threadId) => '/messages/$threadId';

  static const wallet = '/wallet';
  static const friendPicker = '/wallet/send';
  static const rewards = '/rewards';
  static String reward(String id) => '/rewards/$id';
  static const achievements = '/achievements';
  static const store = '/store';
  static String product(String id) => '/store/$id';
}
