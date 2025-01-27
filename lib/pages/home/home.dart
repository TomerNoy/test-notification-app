import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_notification_app/global_providers/user_provider.dart';
import 'package:test_notification_app/pages/home/providers/location_permission_provider.dart';
import 'package:test_notification_app/pages/home/providers/notification_permission_provider.dart';
// import 'package:test_notification_app/pages/home/widgets/debug_overlay.dart';
import 'package:test_notification_app/services/services.dart';

// the main page of the app
class Home extends HookConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName =
        ref.watch(userProvider).valueOrNull?.displayName ?? 'User';

    final notification = ref.watch(notificationPermissionProvider);

    final location = ref.watch(locationProvider);

    final lifecycleState = useAppLifecycleState();

    final ignoreStart = useState(false);

    final lastPress = useState<DateTime?>(null);

    useEffect(() {
      if (lifecycleState == AppLifecycleState.resumed) {
        notificationService
          ..checkPermissions()
          ..handleScheduleTime();
        locationService.checkPermission();
      }
      return;
    }, [lifecycleState]);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final now = DateTime.now();
          if (lastPress.value == null ||
              now.difference(lastPress.value!).inSeconds > 3) {
            lastPress.value = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            await _exitApp();
          }
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Home Page'),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(80),
              child: Column(
                children: [
                  Text(
                    notification.notificationTime == null
                        ? 'Hello ${displayName.toUpperCase()}!\nHow are you today?'
                        : 'The notification\nwill appear at: ${notification.notificationTime?.hour}:${notification.notificationTime?.minute}',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            backgroundColor: Theme.of(context).primaryColor.withAlpha(50),
          ),
          body: Column(
            children: [
              Card(
                child: SizedBox(
                  height: 120,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          color: Theme.of(context).primaryColor.withAlpha(50),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text('Location'),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: location.permissionGranted == null
                                ? CircularProgressIndicator()
                                : location.permissionGranted == true
                                    ? Text(
                                        '${location.address}',
                                        textAlign: TextAlign.center,
                                      )
                                    : ElevatedButton(
                                        onPressed: () => _showLodation(ref),
                                        child: Text('Show Location'),
                                      ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () async => await userService.signOut(),
                child: const Text(
                  'Delete User',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Spacer(),
              IgnorePointer(
                ignoring: notification.notificationTime != null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: notification.notificationTime == null ? 1 : 0,
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: FloatingActionButton(
                      shape: CircleBorder(),
                      heroTag: null,
                      onPressed: () => _start(ref, context, ignoreStart),
                      child:
                          const Text('Start', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.orangeAccent,
            onPressed: _exitApp,
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.black),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat),
    );
  }

  void _showLodation(WidgetRef ref) {
    ref.read(locationProvider.notifier).resetLocation();
    locationService.requestPermission();
  }

  Future<void> _start(
    WidgetRef ref,
    BuildContext context,
    ValueNotifier<bool> ignoreStart,
  ) async {
    if (ignoreStart.value) return;
    ignoreStart.value = true;
    if (ref.read(notificationPermissionProvider).permissionState !=
        NotificationPermissionState.granted) {
      final result = await notificationService.requestPermission();
      if (result.isFailure || result.data == false) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to get notification permission'),
              action: SnackBarAction(
                label: 'Open Settings',
                onPressed: () async => await openAppSettings(),
              ),
            ),
          );
        }
      }
    } else {
      final scheduleTime = DateTime.now().add(Duration(seconds: 5));

      loggerService.info('Notification permission granted');
      final schedule = await notificationService.scheduleNotification(
        'Scheduled Notification',
        'This is your scheduled notification',
        scheduleTime,
      );

      if (schedule.isFailure || schedule.data == false) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                schedule.isFailure
                    ? schedule.error!
                    : 'Failed to schedule notification',
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          final timeFormatted = '${scheduleTime.hour}:${scheduleTime.minute}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification scheduled to $timeFormatted'),
            ),
          );
        }
      }
    }
    Future.delayed(const Duration(seconds: 1), () => ignoreStart.value = false);
  }

  Future<void> _exitApp() async {
    appLifeCycleService.onBackExitPressed();
    await Future.delayed(Duration(milliseconds: 100));
    SystemNavigator.pop();
  }
}
