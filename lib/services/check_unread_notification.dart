// services/notification_service.dart
import 'package:flutter/foundation.dart';

class CheckUnreadNotification {
  static final ValueNotifier<bool> hasUnreadNotifier = ValueNotifier<bool>(
    false,
  );

  static void updateUnreadStatus(bool hasUnread) {
    hasUnreadNotifier.value = hasUnread;
  }

  static bool get hasUnreadNotifications => hasUnreadNotifier.value;
}
