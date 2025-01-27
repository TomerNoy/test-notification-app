import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_notification_app/services/services.dart';

part 'notification_permission_provider.g.dart';

enum NotificationPermissionState { granted, denied }

/// A provider for notification permission

@immutable
class NotificationState {
  final NotificationPermissionState? permissionState;
  final DateTime? notificationTime;

  const NotificationState(
    this.permissionState,
    this.notificationTime,
  );

  NotificationState copyWith({
    NotificationPermissionState? permissionState,
    DateTime? notificationTime,
  }) {
    return NotificationState(
      permissionState ?? this.permissionState,
      notificationTime ?? this.notificationTime,
    );
  }

  @override
  String toString() {
    return 'NotificationState(permissionState: $permissionState, notificationTime: $notificationTime)';
  }
}

@riverpod
class NotificationPermission extends _$NotificationPermission {
  StreamSubscription<PermissionStatus?>? _permissionSubscription;
  StreamSubscription<DateTime?>? _scheduleSubscription;

  @override
  NotificationState build() {
    notificationService.checkPermissions();

    _permissionSubscription =
        notificationService.notificationPermissionsChanges.listen(
      (notificationPermissionState) {
        loggerService.info(
            'Notification permission state: $notificationPermissionState');

        final notificationPermitted = [
          PermissionStatus.granted,
          PermissionStatus.limited,
          PermissionStatus.provisional,
        ].contains(notificationPermissionState);

        state = state.copyWith(
          permissionState: notificationPermitted
              ? NotificationPermissionState.granted
              : NotificationPermissionState.denied,
        );
      },
    );

    _scheduleSubscription = notificationService.scheduledTime.listen(
      (scheduleTime) {
        loggerService.info('Notification schedule time: $scheduleTime');

        state = NotificationState(
          state.permissionState,
          scheduleTime,
        );
      },
    );

    ref.onDispose(
      () {
        _permissionSubscription?.cancel();
        _scheduleSubscription?.cancel();
      },
    );
    return NotificationState(null, null);
  }

  // void setNotificationTime(DateTime time) {
  //   state = state.copyWith(notificationTime: time);
  // }

  void resetNotificationState() {
    state = NotificationState(null, null);
  }
}
