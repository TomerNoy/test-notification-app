import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_notification_app/models/app_user.dart';
import 'package:test_notification_app/services/services.dart';

part 'user_provider.g.dart';

/// A provider for the user state
@riverpod
Stream<AppUser?> user(Ref ref) async* {
  yield* userService.userChanges
      .map<AppUser?>((user) => user)
      .distinct()
      .handleError(
    (error, stackTrace) {
      loggerService.error("Error in user stream: $error", stackTrace);
      return null;
    },
  );
}
