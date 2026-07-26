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
}
