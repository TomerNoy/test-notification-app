import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_notification_app/pages/home/providers/location_permission_provider.dart';
import 'package:test_notification_app/pages/home/providers/notification_permission_provider.dart';

// A widget that displays debug information for testing purposes
class DebugOverlay extends ConsumerWidget {
  const DebugOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);

    final notificationPermission = ref.watch(notificationPermissionProvider);

    return IgnorePointer(
      child: SizedBox.expand(
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black26,
                child: Column(
                  children: [
                    Text('location granted: $location'),
                    Text('notification permissions: $notificationPermission'),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
