import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/user.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/usecases/create_staff_usecase.dart';
import '../../domain/usecases/get_all_users_usecase.dart';
import '../../domain/usecases/create_parking_lot_usecase.dart';
import '../../domain/usecases/update_parking_lot_usecase.dart';
import '../../domain/usecases/delete_parking_lot_usecase.dart';

// Admin Data Source Provider
final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.read(dioProvider));
});

// Admin Repository Provider
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(
    remoteDataSource: ref.read(adminRemoteDataSourceProvider),
  );
});

// Use Case Providers
final getAllUsersUseCaseProvider = Provider<GetAllUsersUseCase>((ref) {
  return GetAllUsersUseCase(ref.read(adminRepositoryProvider));
});

final createStaffUseCaseProvider = Provider<CreateStaffUseCase>((ref) {
  return CreateStaffUseCase(ref.read(adminRepositoryProvider));
});

final createParkingLotUseCaseProvider = Provider<CreateParkingLotUseCase>((
  ref,
) {
  return CreateParkingLotUseCase(ref.read(adminRepositoryProvider));
});

final updateParkingLotUseCaseProvider = Provider<UpdateParkingLotUseCase>((
  ref,
) {
  return UpdateParkingLotUseCase(ref.read(adminRepositoryProvider));
});

final deleteParkingLotUseCaseProvider = Provider<DeleteParkingLotUseCase>((
  ref,
) {
  return DeleteParkingLotUseCase(ref.read(adminRepositoryProvider));
});

// State
class UserManagementState {
  final bool isLoading;
  final List<User> users;
  final String? errorMessage;
  final bool isCreating;

  const UserManagementState({
    this.isLoading = false,
    this.users = const [],
    this.errorMessage,
    this.isCreating = false,
  });

  UserManagementState copyWith({
    bool? isLoading,
    List<User>? users,
    String? errorMessage,
    bool? isCreating,
  }) {
    return UserManagementState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      errorMessage: errorMessage,
      isCreating: isCreating ?? this.isCreating,
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final GetAllUsersUseCase getAllUsersUseCase;
  final CreateStaffUseCase createStaffUseCase;
  final CreateParkingLotUseCase createParkingLotUseCase;
  final UpdateParkingLotUseCase updateParkingLotUseCase;
  final DeleteParkingLotUseCase deleteParkingLotUseCase;

  UserManagementNotifier({
    required this.getAllUsersUseCase,
    required this.createStaffUseCase,
    required this.createParkingLotUseCase,
    required this.updateParkingLotUseCase,
    required this.deleteParkingLotUseCase,
  }) : super(const UserManagementState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getAllUsersUseCase();

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (users) {
        state = state.copyWith(isLoading: false, users: users);
      },
    );
  }

  Future<bool> createStaff({
    required String name,
    required String email,
    required String password,
    String? phone,
    required int role,
  }) async {
    state = state.copyWith(isCreating: true, errorMessage: null);

    final result = await createStaffUseCase(
      CreateStaffParams(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      ),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isCreating: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = state.copyWith(
          isCreating: false,
          users: [...state.users, user],
        );
        return true;
      },
    );
  }

  Future<bool> createParkingLot({
    required String name,
    required String address,
    required int totalSlots,
    required double pricePerHour,
    double? latitude,
    double? longitude,
    int? managerId,
    bool? hasEvStation,
  }) async {
    state = state.copyWith(isCreating: true, errorMessage: null);

    final result = await createParkingLotUseCase(
      CreateParkingLotParams(
        name: name,
        address: address,
        totalSlots: totalSlots,
        pricePerHour: pricePerHour,
        latitude: latitude,
        longitude: longitude,
        managerId: managerId,
        hasEvStation: hasEvStation,
      ),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isCreating: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(isCreating: false);
        return true;
      },
    );
  }

  Future<bool> updateParkingLot({
    required int id,
    required String name,
    required String address,
    required int totalSlots,
    required double pricePerHour,
    double? latitude,
    double? longitude,
    int? managerId,
    bool? hasEvStation,
  }) async {
    state = state.copyWith(isCreating: true, errorMessage: null);

    final result = await updateParkingLotUseCase(
      UpdateParkingLotParams(
        id: id,
        name: name,
        address: address,
        totalSlots: totalSlots,
        pricePerHour: pricePerHour,
        latitude: latitude,
        longitude: longitude,
        managerId: managerId,
        hasEvStation: hasEvStation,
      ),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isCreating: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(isCreating: false);
        return true;
      },
    );
  }

  Future<bool> deleteParkingLot(int id) async {
    state = state.copyWith(isCreating: true, errorMessage: null);

    final result = await deleteParkingLotUseCase(id);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isCreating: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(isCreating: false);
        return true;
      },
    );
  }
}

final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
      return UserManagementNotifier(
        getAllUsersUseCase: ref.read(getAllUsersUseCaseProvider),
        createStaffUseCase: ref.read(createStaffUseCaseProvider),
        createParkingLotUseCase: ref.read(createParkingLotUseCaseProvider),
        updateParkingLotUseCase: ref.read(updateParkingLotUseCaseProvider),
        deleteParkingLotUseCase: ref.read(deleteParkingLotUseCaseProvider),
      );
    });
