import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test_notification_app/core/app.dart';
import 'package:test_notification_app/services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServiceProvider.init();

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App();
  }
}
