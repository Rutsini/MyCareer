import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flutter_local_notification_gateway.dart';
import 'local_notification_gateway.dart';

final localNotificationGatewayProvider = Provider<LocalNotificationGateway>(
  (ref) => FlutterLocalNotificationGateway(),
);
