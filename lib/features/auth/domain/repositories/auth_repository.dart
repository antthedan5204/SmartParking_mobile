import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  });

  Future<Either<Failure, User>> getProfile();

  Future<Either<Failure, User>> updateProfile({
    required int id,
    required String name,
    String? phone,
  });

  Future<void> logout();

  Future<bool> isLoggedIn();

  Future<String?> getToken();
  
  Future<Either<Failure, User>> loginWithGoogle(String idToken);
  
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  
  Future<Either<Failure, void>> verifyResetToken({
    required String email,
    required String token,
  });
  
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });
}
