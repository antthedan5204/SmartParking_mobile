class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException({this.message = 'Server error', this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  NetworkException({this.message = 'Network error'});
}

class CacheException implements Exception {
  final String message;
  CacheException({this.message = 'Cache error'});
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException({this.message = 'Unauthorized'});
}
