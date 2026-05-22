import 'package:flutter/material.dart';
import '../widgets/app_notification.dart';

class NotificationHelper {
  static void show(BuildContext context, String message) {
    AppNotificationState? state;
    try {
      state = AppNotification.of(context);
    } catch (_) {}
    state?.showNotification(message);
  }
}
