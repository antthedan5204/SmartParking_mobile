import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/core/error/failures.dart';
import 'package:smart_parking/features/auth/domain/entities/user.dart';
import 'package:smart_parking/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_parking/features/auth/domain/usecases/login_usecase.dart';
import 'package:smart_parking/features/auth/domain/usecases/register_usecase.dart';
import 'package:smart_parking/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository implements AuthRepository {
  bool sendVerificationEmailCalled = false;
  String? sentEmail;
  bool shouldSendVerificationEmailSucceed = true;

  bool verifyEmailCalled = false;
  String? verifiedEmail;
  String? verifiedToken;
  bool shouldVerifyEmailSucceed = true;
  User? dummyUser;

  @override
  Future<Either<Failure, void>> sendVerificationEmail(String email) async {
    sendVerificationEmailCalled = true;
    sentEmail = email;
    if (shouldSendVerificationEmailSucceed) {
      return const Right(null);
    } else {
      return Left(ServerFailure('Failed to send verification email'));
    }
  }

  @override
  Future<Either<Failure, User>> verifyEmail({
    required String email,
    required String token,
  }) async {
    verifyEmailCalled = true;
    verifiedEmail = email;
    verifiedToken = token;
    if (shouldVerifyEmailSucceed) {
      return Right(dummyUser ?? const User(id: 1, name: 'Test User', email: 'test@example.com', role: 'User'));
    } else {
      return Left(ServerFailure('Invalid verification token'));
    }
  }

  // Dummy implementations of unused repository methods
  @override
  Future<Either<Failure, User>> login({required String email, required String password}) async => Left(ServerFailure('Unused'));
  @override
  Future<Either<Failure, User>> register({required String name, required String email, required String password, String? phone}) async => Left(ServerFailure('Unused'));
  @override
  Future<Either<Failure, User>> getProfile() async => Left(ServerFailure('Unused'));
  @override
  Future<Either<Failure, User>> updateProfile({required int id, required String name, String? phone}) async => Left(ServerFailure('Unused'));
  @override
  Future<void> logout() async {}
  @override
  Future<bool> isLoggedIn() async => false;
  @override
  Future<String?> getToken() async => null;
  @override
  Future<Either<Failure, User>> loginWithGoogle(String idToken) async => Left(ServerFailure('Unused'));
  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async => Left(ServerFailure('Unused'));
  @override
  Future<Either<Failure, void>> verifyResetToken({required String email, required String token}) async => Left(ServerFailure('Unused'));
  @override
  Future<Either<Failure, void>> resetPassword({required String email, required String token, required String newPassword}) async => Left(ServerFailure('Unused'));
}

class MockLoginUseCase implements LoginUseCase {
  @override
  AuthRepository get repository => throw UnimplementedError();
  @override
  Future<Either<Failure, User>> call({required String email, required String password}) async => Left(ServerFailure('Unused'));
}

class MockRegisterUseCase implements RegisterUseCase {
  @override
  AuthRepository get repository => throw UnimplementedError();
  @override
  Future<Either<Failure, User>> call({required String name, required String email, required String password, String? phone}) async => Left(ServerFailure('Unused'));
}

void main() {
  late MockAuthRepository mockRepository;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late AuthNotifier authNotifier;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    
    // Set up dummy user
    mockRepository.dummyUser = const User(
      id: 123,
      name: 'Verified User',
      email: 'verified@example.com',
      role: 'User',
    );

    authNotifier = AuthNotifier(
      repository: mockRepository,
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
    );
  });

  group('Email Verification Tests', () {
    test('sendVerificationEmail should call repository and return true on success', () async {
      final result = await authNotifier.sendVerificationEmail('test@example.com');
      
      expect(mockRepository.sendVerificationEmailCalled, isTrue);
      expect(mockRepository.sentEmail, 'test@example.com');
      expect(result, isTrue);
    });

    test('sendVerificationEmail should return false and set error state on failure', () async {
      mockRepository.shouldSendVerificationEmailSucceed = false;
      
      final result = await authNotifier.sendVerificationEmail('test@example.com');
      
      expect(mockRepository.sendVerificationEmailCalled, isTrue);
      expect(result, isFalse);
      expect(authNotifier.state.status, AuthStatus.error);
      expect(authNotifier.state.errorMessage, 'Failed to send verification email');
    });

    test('verifyEmail should call repository and transition to authenticated status on success', () async {
      final result = await authNotifier.verifyEmail(
        email: 'test@example.com',
        token: '123456',
      );
      
      expect(mockRepository.verifyEmailCalled, isTrue);
      expect(mockRepository.verifiedEmail, 'test@example.com');
      expect(mockRepository.verifiedToken, '123456');
      expect(result, isTrue);
      expect(authNotifier.state.status, AuthStatus.authenticated);
      expect(authNotifier.state.user?.id, 123);
      expect(authNotifier.state.user?.name, 'Verified User');
    });

    test('verifyEmail should return false and set error state on failure', () async {
      mockRepository.shouldVerifyEmailSucceed = false;
      
      final result = await authNotifier.verifyEmail(
        email: 'test@example.com',
        token: '000000',
      );
      
      expect(mockRepository.verifyEmailCalled, isTrue);
      expect(result, isFalse);
      expect(authNotifier.state.status, AuthStatus.error);
      expect(authNotifier.state.errorMessage, 'Invalid verification token');
      expect(authNotifier.state.user, isNull);
    });
  });
}
