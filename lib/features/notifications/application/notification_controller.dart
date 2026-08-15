import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/notifications/local_notification_gateway.dart';
import '../../../core/notifications/notification_payload.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../data/repositories/evaluation_repository.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../evaluations/application/evaluation_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../subjects/application/subject_controller.dart';
import 'notification_scheduler.dart';

final notificationSchedulerProvider = Provider((ref) =>
    NotificationScheduler(ref.watch(localNotificationGatewayProvider)));

final notificationCoordinatorProvider =
    Provider((ref) => NotificationCoordinator(
          ref.watch(localNotificationGatewayProvider),
          ref.watch(notificationSchedulerProvider),
          ref.watch(userProfileRepositoryProvider),
          ref.watch(evaluationRepositoryProvider),
          ref.watch(subjectRepositoryProvider),
          onNavigationRequested: (route) =>
              ref.read(pendingNotificationRouteProvider.notifier).state = route,
        ));

final notificationPermissionProvider =
    StateProvider<NotificationPermissionState>(
        (ref) => NotificationPermissionState.unknown);
final pendingNotificationRouteProvider = StateProvider<String?>((ref) => null);

final notificationBootstrapProvider = FutureProvider<void>((ref) async {
  final coordinator = ref.watch(notificationCoordinatorProvider);
  await coordinator.initialize();
  ref.read(notificationPermissionProvider.notifier).state =
      await coordinator.permissionStatus();
  await coordinator.synchronize();
});

class NotificationCoordinator {
  NotificationCoordinator(
    this.gateway,
    this.scheduler,
    this.profileRepository,
    this.evaluationRepository,
    this.subjectRepository, {
    this.onNavigationRequested,
  });

  final LocalNotificationGateway gateway;
  final NotificationScheduler scheduler;
  final UserProfileRepository profileRepository;
  final EvaluationRepository evaluationRepository;
  final SubjectRepository subjectRepository;
  final void Function(String route)? onNavigationRequested;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await gateway.initialize(onTap: _handlePayload);
    final initial = gateway.takeInitialPayload();
    if (initial != null) _handlePayload(initial);
  }

  void _handlePayload(String raw) {
    final payload = NotificationPayload.tryParse(raw);
    if (payload != null) {
      onNavigationRequested
          ?.call(AppRoutes.editEvaluation(payload.evaluationId));
    }
  }

  Future<NotificationPermissionState> permissionStatus() =>
      gateway.permissionStatus();

  Future<bool> requestPermission() => gateway.requestPermission();

  Future<void> synchronize() async {
    final profile = await profileRepository.watchProfile().first;
    final evaluations = await evaluationRepository.watchEvaluations().first;
    final subjects = await subjectRepository.watchSubjects().first;
    await scheduler.synchronizeAll(
      settings: profile.settings.notifications,
      evaluations: evaluations,
      subjects: subjects,
    );
  }

  Future<void> cancelAcademic() async {
    final ids = await gateway.pendingIds();
    for (final id in ids) {
      if (id >= 100000000 && id < 2100000000) await gateway.cancel(id);
    }
  }

  Future<void> showTest() => gateway.show(
        id: 42,
        title: 'MyCareer',
        body: 'Las notificaciones están funcionando correctamente.',
      );
}
