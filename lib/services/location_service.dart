import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_notification_app/models/result.dart';
import 'package:test_notification_app/services/services.dart';

// this class is responsible for handling location services
class LocationService {
  final _locationPermissions = BehaviorSubject<LocationPermission?>();

  Stream<LocationPermission?> get locationPermissionsChanges =>
      _locationPermissions.stream;

  bool get permissionGranted =>
      _locationPermissions.valueOrNull == LocationPermission.always ||
      _locationPermissions.valueOrNull == LocationPermission.whileInUse;

  Future<Result<void>> checkPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      _locationPermissions.add(permission);
      loggerService.info('Location permission check state: $permission');
      return Result.success(null);
    } catch (e) {
      loggerService.error('Error checking location permission: $e');
      return Result.failure('Error checking location permission');
    }
  }

  Future<void> requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    _locationPermissions.add(permission);
    loggerService.info('Location permission request state: $permission');
  }

  // determine the current position of the device
  Future<Result<Position>> _determinePosition() async {
    if (!permissionGranted) {
      loggerService.error('Tried to get location without permission');
      return Result.failure('Location permission not granted');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      loggerService.error('Location services are disabled.');
      return Result.failure('Location services are disabled');
    }

    final location = await Geolocator.getCurrentPosition();

    return Result.success(location);
  }

  Future<Result<String>> _getAddressFromLatLong(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        final address =
            '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
        return Result.success(address);
      }
    } catch (e) {
      loggerService.error('Error getting address from lat long: $e');
    }
    return Result.failure('Unable to get address');
  }

  Future<Result<String>> getCurrentAddress() async {
    var position = await _determinePosition();
    if (position.isFailure) {
      return Result.failure(position.error!);
    }

    return await _getAddressFromLatLong(position.data!);
  }

  void dispose() {
    _locationPermissions.close();
  }
}
