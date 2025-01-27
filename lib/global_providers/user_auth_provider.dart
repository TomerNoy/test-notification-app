import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_notification_app/services/services.dart';

part 'user_auth_provider.g.dart';

enum UserAuthState { authenticated, unauthenticated, hasError, loading }

/// A provider for user authentication
@riverpod
Stream<UserAuthState> userAuth(Ref ref) async* {
  yield UserAuthState.loading;

  yield* userService.authStateChanges.distinct().handleError(
    (error, stackTrace) {
      loggerService.error("Error in userAuth stream: $error", stackTrace);
      return UserAuthState.hasError;
    },
  );
}
