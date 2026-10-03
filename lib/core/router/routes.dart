class Routes {
  const Routes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const register = '/register';

  static const home = '/home';
  static const history = '/history';
  static const splitBill = '/split-bill';
  static const travelMode = '/travel-mode';

  static const search = '/search';
  static const settings = '/settings';

  // Split Bill steps for one bill: splitters → menu → summary.
  static const bill = '/bills/:id';
  static String billSplitters(String id) => '/bills/$id';
  static String billMenu(String id) => '/bills/$id/menu';
  static String billSummary(String id) => '/bills/$id/summary';
}
