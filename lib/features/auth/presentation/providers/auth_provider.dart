import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/network/dio_client.dart';

// Data source provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.read(dioProvider));
});

// Firebase Auth Service provider
final firebaseAuthProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    secureStorage: ref.read(secureStorageProvider),
    firebaseAuthService: ref.read(firebaseAuthProvider),
  );
});

// Use case providers
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
});

// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

  AuthNotifier({
    required this.repository,
    required this.loginUseCase,
    required this.registerUseCase,
  }) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final isLoggedIn = await repository.isLoggedIn();
    if (isLoggedIn) {
      final result = await repository.getProfile();
      result.fold(
        (failure) {
          state = const AuthState(status: AuthStatus.unauthenticated);
        },
        (user) {
          AuthInterceptor.clearTokenCache();
          state = AuthState(status: AuthStatus.authenticated, user: user);
        },
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await loginUseCase(email: email, password: password);

    return result.fold(
      (failure) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        AuthInterceptor.clearTokenCache();
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      },
    );
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final firebaseAuth = FirebaseAuthService();
      final userCredential = await firebaseAuth.signInWithGoogle();
      
      if (userCredential == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return false;
      }

      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Could not get ID token from Google',
        );
        return false;
      }

      final result = await repository.loginWithGoogle(idToken);

      return result.fold(
        (failure) {
          state = AuthState(
            status: AuthStatus.error,
            errorMessage: failure.message,
          );
          return false;
        },
        (user) {
          AuthInterceptor.clearTokenCache();
          state = AuthState(status: AuthStatus.authenticated, user: user);
          return true;
        },
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    final previousState = state;
    state = state.copyWith(status: AuthStatus.loading);

    final result = await repository.sendPasswordResetEmail(email);

    return result.fold(
      (failure) {
        state = previousState.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = previousState.copyWith(
          status: previousState.status == AuthStatus.loading
              ? AuthStatus.unauthenticated
              : previousState.status,
        );
        return true;
      },
    );
  }

  Future<bool> verifyResetToken({
    required String email,
    required String token,
  }) async {
    final previousState = state;
    state = state.copyWith(status: AuthStatus.loading);

    final result = await repository.verifyResetToken(
      email: email,
      token: token,
    );

    return result.fold(
      (failure) {
        state = previousState.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = previousState.copyWith(
          status: previousState.status == AuthStatus.loading
              ? AuthStatus.unauthenticated
              : previousState.status,
        );
        return true;
      },
    );
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await repository.resetPassword(
      email: email,
      token: token,
      newPassword: newPassword,
    );

    return result.fold(
      (failure) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return true;
      },
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await registerUseCase(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );

    return result.fold(
      (failure) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return true;
      },
    );
  }

  Future<bool> sendVerificationEmail(String email) async {
    final previousState = state;
    state = state.copyWith(status: AuthStatus.loading);

    final result = await repository.sendVerificationEmail(email);

    return result.fold(
      (failure) {
        state = previousState.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = previousState.copyWith(
          status: previousState.status == AuthStatus.loading
              ? AuthStatus.unauthenticated
              : previousState.status,
        );
        return true;
      },
    );
  }

  Future<bool> verifyEmail({
    required String email,
    required String token,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await repository.verifyEmail(
      email: email,
      token: token,
    );

    return result.fold(
      (failure) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    await repository.logout();
    AuthInterceptor.clearTokenCache();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> updateProfile({
    required int id,
    required String name,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await repository.updateProfile(
      id: id,
      name: name,
      phone: phone,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.authenticated, // Keep authenticated even if update fails
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        return true;
      },
    );
  }
}

// Main auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    repository: ref.read(authRepositoryProvider),
    loginUseCase: ref.read(loginUseCaseProvider),
    registerUseCase: ref.read(registerUseCaseProvider),
  );
});
