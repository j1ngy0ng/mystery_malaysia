class AppLocation {
  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMetres,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMetres;

  String get coordinateLabel =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  bool get couldBeInMalaysia =>
      _within(0.8, 7.5, 99.5, 105.0) || _within(0.8, 7.6, 109.0, 119.5);

  bool _within(
    double minimumLatitude,
    double maximumLatitude,
    double minimumLongitude,
    double maximumLongitude,
  ) =>
      latitude >= minimumLatitude &&
      latitude <= maximumLatitude &&
      longitude >= minimumLongitude &&
      longitude <= maximumLongitude;
}
