abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/';
  static const subjects = '/subjects';
  static const calendar = '/calendar';
  static const progress = '/progress';
  static const profile = '/profile';

  static const authenticated = <String>{
    dashboard,
    subjects,
    calendar,
    progress,
    profile,
  };
}
