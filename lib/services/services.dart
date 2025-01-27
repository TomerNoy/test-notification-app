import 'package:get_it/get_it.dart';
import 'package:test_notification_app/services/app_lifecycle_service.dart';
import 'package:test_notification_app/services/location_service.dart';
import 'package:test_notification_app/services/logger_service.dart';
import 'package:test_notification_app/services/notification_service.dart';
import 'package:test_notification_app/services/user_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// this class is the main service provider
class ServiceProvider {
  static final _getIt = GetIt.instance;

  static Future<void> init() async {
    try {
      // logger
      _getIt.registerSingleton<LoggerService>(LoggerService());

      await _getIt.allReady();

      await dotenv.load(fileName: ".env");

      // notification servicesendAliveStatus
      _getIt.registerSingletonAsync<NotificationService>(
        () async {
          final notificationService = NotificationService();
          await notificationService.initialize();
          return notificationService;
        },
        dispose: (service) => service.dispose,
      );

      await _getIt.allReady();

      // user service
      _getIt.registerSingleton<UserService>(UserService(),
          dispose: (service) => service.dispose);

      await _getIt.allReady();

      // location service
      _getIt.registerLazySingleton<LocationService>(
        () => LocationService(),
        dispose: (service) => service.dispose,
      );

      await _getIt.allReady();

      // app life cycle
      _getIt.registerSingleton<AppLifeCycleService>(
        AppLifeCycleService(),
        dispose: (service) => service.dispose,
      );

      await _getIt.allReady();
    } catch (e, st) {
      loggerService.error('services error', e, st);
    }
  }
}

LoggerService get loggerService {
  return ServiceProvider._getIt.get<LoggerService>();
}

NotificationService get notificationService {
  return ServiceProvider._getIt.get<NotificationService>();
}

UserService get userService {
  return ServiceProvider._getIt.get<UserService>();
}

LocationService get locationService {
  return ServiceProvider._getIt.get<LocationService>();
}

AppLifeCycleService get appLifeCycleService {
  return ServiceProvider._getIt.get<AppLifeCycleService>();
}
