import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Lỗi máy chủ']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Lỗi kết nối mạng']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'cacheError']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Lỗi xác thực']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'validationError']);
}
