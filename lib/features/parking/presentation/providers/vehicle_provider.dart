import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/parking_repository.dart';
import 'parking_provider.dart';

class VehicleState {
  final List<Vehicle> vehicles;
  final bool isLoading;
  final String? errorMessage;

  const VehicleState({
    this.vehicles = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  VehicleState copyWith({
    List<Vehicle>? vehicles,
    bool? isLoading,
    String? errorMessage,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  final ParkingRepository repository;

  VehicleNotifier(this.repository) : super(const VehicleState()) {
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await repository.getUserVehicles();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (vehicles) =>
          state = state.copyWith(isLoading: false, vehicles: vehicles),
    );
  }

  Future<bool> addVehicle({
    required String licensePlate,
    required String model,
    String? color,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await repository.addVehicle(
      licensePlate: licensePlate,
      model: model,
      color: color,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (vehicle) {
        state = state.copyWith(
          isLoading: false,
          vehicles: [...state.vehicles, vehicle],
        );
        return true;
      },
    );
  }

  Future<bool> deleteVehicle(int id) async {
    final result = await repository.deleteVehicle(id);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          vehicles: state.vehicles.where((v) => v.id != id).toList(),
        );
        return true;
      },
    );
  }
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, VehicleState>((
  ref,
) {
  final repository = ref.read(parkingRepositoryProvider);
  return VehicleNotifier(repository);
});
