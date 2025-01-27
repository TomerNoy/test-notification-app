import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_notification_app/services/services.dart';

part 'location_permission_provider.g.dart';

// this provider is used to manage the location permission state
@immutable
class LocationState {
  final bool? permissionGranted;
  final String? address;

  const LocationState(
    this.permissionGranted,
    this.address,
  );

  LocationState copyWith({
    bool? permissionGranted,
    String? address,
  }) {
    return LocationState(
      permissionGranted ?? this.permissionGranted,
      address ?? this.address,
    );
  }

  @override
  String toString() {
    return 'LocationState(permissionGranted: $permissionGranted, address: $address)';
  }
}

@riverpod
class Location extends _$Location {
  StreamSubscription<LocationPermission?>? _subscription;

  @override
  LocationState build() {
    locationService.checkPermission();
    _subscription = locationService.locationPermissionsChanges.listen(
      (locationPermissionState) async {
        loggerService
            .info('Location permission state: $locationPermissionState');

        final locationPermitted = [
          LocationPermission.always,
          LocationPermission.whileInUse,
        ].contains(locationPermissionState);

        if (locationPermitted) {
          final addressResult = await locationService.getCurrentAddress();
          if (addressResult.isSuccess) {
            state = state.copyWith(
              permissionGranted: locationPermitted,
              address: addressResult.data,
            );
          }

          return;
        }
        state = state.copyWith(
          permissionGranted: locationPermitted,
          address: null,
        );
      },
    );

    ref.onDispose(
      () => _subscription?.cancel(),
    );

    return LocationState(null, null);
  }

  void resetLocation() {
    state = LocationState(null, null);
  }
}
