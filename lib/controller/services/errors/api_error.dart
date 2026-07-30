class ApiError implements Exception {
  const ApiError(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
