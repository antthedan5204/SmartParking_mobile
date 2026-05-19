import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/admin_repository.dart';

class CreateStaffParams {
  final String name;
  final String email;
  final String password;
  final String? phone;
  final int role;

  CreateStaffParams({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    required this.role,
  });
}

class CreateStaffUseCase {
  final AdminRepository repository;

  CreateStaffUseCase(this.repository);

  Future<Either<Failure, User>> call(CreateStaffParams params) {
    return repository.createStaff(
      name: params.name,
      email: params.email,
      password: params.password,
      phone: params.phone,
      role: params.role,
    );
  }
}
