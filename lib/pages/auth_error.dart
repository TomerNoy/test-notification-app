import 'package:flutter/material.dart';
import 'package:test_notification_app/services/services.dart';

// auth error page
class AuthError extends StatelessWidget {
  const AuthError({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48),
            SizedBox(height: 16),
            Text('An error occurred while authenticating, please try again'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => userService.signOut(),
              child: Text('return to register'),
            ),
          ],
        ),
      ),
    );
  }
}
