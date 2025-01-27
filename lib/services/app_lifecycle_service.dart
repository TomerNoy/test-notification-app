import 'dart:async';
import 'package:flutter/material.dart';
import 'package:test_notification_app/services/services.dart';

// A service to handle the app lifecycle and update firebase
class AppLifeCycleService extends WidgetsBindingObserver {
  Timer? _timer;
  String? _lastSentState;
  bool _backExitPressed = false;

  AppLifeCycleService() {
    WidgetsBinding.instance.addObserver(this);
    sendAppLifecycleState(AppLifecycleState.resumed.name);
    _lastSentState = AppLifecycleState.resumed.name;
    _startAppLifecycleStateTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    loggerService.debug('app state: ${state.name}');

    if (state.name != _lastSentState) {
      sendAppLifecycleState(state.name);
      _lastSentState = state.name;
    }

    if (state == AppLifecycleState.resumed) {
      _startAppLifecycleStateTimer();
    } else if (state == AppLifecycleState.detached) {
      _backExitPressed = false;
      _stopAppLifecycleStateTimer();
    }
  }

  void _startAppLifecycleStateTimer() {
    _timer?.cancel();
    // Change this duration to 1 minute
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      sendAppLifecycleState(_lastSentState ?? 'not set');
    });
  }

  void _stopAppLifecycleStateTimer() {
    _timer?.cancel();
  }

  void onBackExitPressed() => _backExitPressed = true;

  Future<void> sendAppLifecycleState(String stateName) async {
    await userService.setAppLifecycleState(
      'state: $stateName gracefulExit:$_backExitPressed',
    );
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    sendAppLifecycleState(AppLifecycleState.detached.name);
    _stopAppLifecycleStateTimer();
  }
}
