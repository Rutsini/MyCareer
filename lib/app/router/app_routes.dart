abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/';
  static const subjects = '/subjects';
  static const newSubject = '/subjects/new';
  static const newCurrentSubject = '/subjects/new/current';
  static const newHistoricalSubject = '/subjects/new/historical';
  static String subject(String id) => '/subjects/$id';
  static String editSubject(String id) => '/subjects/$id/edit';
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
