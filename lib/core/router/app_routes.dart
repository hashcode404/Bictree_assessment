class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const password = '/signup/password';
  static const fingerprint = '/signup/fingerprint';

  static const home = '/home';
  static const menu = '/menu';
  static const search = '/search';
  static const food = '/food/:id';
  static const cart = '/cart';
  static const confirm = '/confirm';

  static String foodPath(int id) => '/food/$id';
}
