import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/services/firebase_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage secureStorage;
  final FirebaseAuthService firebaseAuthService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.firebaseAuthService,
  });

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save token and user data
      if (user.token != null) {
        await secureStorage.write(
          key: AppConstants.tokenKey,
          value: user.token!,
        );
      }
      await secureStorage.write(
        key: AppConstants.userKey,
        value: json.encode(user.toJson()),
      );

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final user = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final user = await remoteDataSource.getProfile();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException {
      return const Left(AuthFailure('sessionExpired'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    required int id,
    required String name,
    String? phone,
  }) async {
    try {
      final user = await remoteDataSource.updateProfile(
        id: id,
        name: name,
        phone: phone,
      );

      // Update cached user data
      final userData = await secureStorage.read(key: AppConstants.userKey);
      if (userData != null) {
        final Map<String, dynamic> userMap = json.decode(userData);
        userMap['name'] = name;
        if (phone != null) userMap['phone'] = phone;
        await secureStorage.write(
          key: AppConstants.userKey,
          value: json.encode(userMap),
        );
      }

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await secureStorage.delete(key: AppConstants.tokenKey);
    await secureStorage.delete(key: AppConstants.userKey);
    await firebaseAuthService.signOut();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await secureStorage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getToken() async {
    return await secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<User?> getCachedUser() async {
    final userData = await secureStorage.read(key: AppConstants.userKey);
    if (userData != null) {
      return UserModel.fromJson(json.decode(userData));
    }
    return null;
  }
  @override
  Future<Either<Failure, User>> loginWithGoogle(String idToken) async {
    try {
      final user = await remoteDataSource.googleLogin(idToken: idToken);

      // Save token and user data
      if (user.token != null) {
        await secureStorage.write(
          key: AppConstants.tokenKey,
          value: user.token!,
        );
      }
      await secureStorage.write(
        key: AppConstants.userKey,
        value: json.encode(user.toJson()),
      );

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendForgotPasswordEmail(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyResetToken({
    required String email,
    required String token,
  }) async {
    try {
      await remoteDataSource.verifyResetToken(email: email, token: token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendVerificationEmail(String email) async {
    try {
      await remoteDataSource.sendVerificationEmail(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> verifyEmail({
    required String email,
    required String token,
  }) async {
    try {
      final user = await remoteDataSource.verifyEmail(
        email: email,
        token: token,
      );

      // Save token and user data to cache
      if (user.token != null) {
        await secureStorage.write(
          key: AppConstants.tokenKey,
          value: user.token!,
        );
      }
      await secureStorage.write(
        key: AppConstants.userKey,
        value: json.encode(user.toJson()),
      );

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
