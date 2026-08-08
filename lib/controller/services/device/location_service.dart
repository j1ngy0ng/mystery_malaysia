import 'package:geolocator/geolocator.dart';

import '../../../model/active_mission/app_location.dart';
import '../config/app_config.dart';

class LocationService {
  Future<AppLocation> getCurrentLocation() async {
    if (AppConfig.demoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return const AppLocation(
        latitude: 3.16312,
        longitude: 101.71208,
        accuracyMetres: 8,
      );
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceException(
        'Turn on device location to continue.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission is needed for mystery missions.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is blocked. Enable it in Android Settings.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracy,
      );
    } catch (_) {
      throw const LocationServiceException(
        'We could not detect your location. Please try again.',
      );
    }
  }

  int distanceMetres(AppLocation from, AppLocation to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ).round();
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
