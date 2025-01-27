import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test_notification_app/global_providers/user_auth_provider.dart';
import 'package:test_notification_app/pages/auth_error.dart';
import 'package:test_notification_app/pages/home/home.dart';
import 'package:test_notification_app/pages/loading.dart';
import 'package:test_notification_app/pages/register.dart';
import 'package:test_notification_app/services/services.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(userAuthProvider);

    loggerService.debug('authState: $authState');

    return MaterialApp(
      title: 'Notification Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (state) {
          switch (state) {
            case UserAuthState.authenticated:
              return const Home();
            case UserAuthState.unauthenticated:
              return const Register();
            case UserAuthState.hasError:
              return const AuthError();
            case UserAuthState.loading:
              return Loading();
          }
        },
        loading: () => Loading(),
        error: (_, __) => const Scaffold(
          body: Center(child: Text('Error occurred')),
        ),
      ),
      routes: {
        '/register': (context) => const Register(),
        '/home': (context) => const Home(),
        '/loading': (context) => const Loading(),
        '/auth_error': (context) => const AuthError(),
      },
    );
  }
}
