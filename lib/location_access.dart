import 'package:geolocator/geolocator.dart';

/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.
Future<bool> setUpLocation() async {
  bool serviceEnabled;
  LocationPermission permission;
  LocationAccuracyStatus accuracy = LocationAccuracyStatus.reduced;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future<bool>.value(false);
    }
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      // await Geolocator.openAppSettings();
      return Future<bool>.value(false);
    }
  }

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openAppSettings();
    permission = await Geolocator.requestPermission();
    if (!(permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse)) {
      return Future.value(false);
    }
  }
  if ((permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse)) {
    accuracy = await Geolocator.getLocationAccuracy();
    if (accuracy != LocationAccuracyStatus.precise) {
      await Geolocator.openAppSettings();
      accuracy = await Geolocator.getLocationAccuracy();
      if (accuracy != LocationAccuracyStatus.precise) {
        return Future<bool>.value(false);
      }
    }
  }
  await Geolocator.getCurrentPosition();
  return Future<bool>.value(true);
}
