import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/admin_repository.dart';

class GetAllUsersUseCase {
  final AdminRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<Either<Failure, List<User>>> call() {
    return repository.getAllUsers();
  }
}
