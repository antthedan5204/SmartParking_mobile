import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/location_service.dart';
import '../../data/datasources/parking_remote_datasource.dart';
import '../../data/repositories/parking_repository_impl.dart';
import '../../domain/entities/parking_lot.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/repositories/parking_repository.dart';
import '../../domain/usecases/get_parking_lots_usecase.dart';

// Data source provider
final parkingRemoteDataSourceProvider = Provider<ParkingRemoteDataSource>((ref) {
  return ParkingRemoteDataSource(ref.read(dioProvider));
});

// Repository provider
final parkingRepositoryProvider = Provider<ParkingRepository>((ref) {
  return ParkingRepositoryImpl(
    remoteDataSource: ref.read(parkingRemoteDataSourceProvider),
  );
});

// Use case providers
final getParkingLotsUseCaseProvider = Provider<GetParkingLotsUseCase>((ref) {
  return GetParkingLotsUseCase(ref.read(parkingRepositoryProvider));
});

// Parking lots state
class ParkingLotsState {
  final bool isLoading;
  final List<ParkingLot> lots;
  final String? errorMessage;
  final String searchQuery;

  // Cached filtered results – avoids creating a new list on every widget rebuild.
  final List<ParkingLot> filteredLots;

  const ParkingLotsState({
    this.isLoading = false,
    this.lots = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.filteredLots = const [],
  });

  ParkingLotsState copyWith({
    bool? isLoading,
    List<ParkingLot>? lots,
    String? errorMessage,
    String? searchQuery,
  }) {
    final newLots = lots ?? this.lots;
    final newQuery = searchQuery ?? this.searchQuery;

    return ParkingLotsState(
      isLoading: isLoading ?? this.isLoading,
      lots: newLots,
      errorMessage: errorMessage,
      searchQuery: newQuery,
      filteredLots: _computeFiltered(newLots, newQuery),
    );
  }

  static List<ParkingLot> _computeFiltered(List<ParkingLot> lots, String query) {
    if (query.isEmpty) return lots;
    final lowerQuery = query.toLowerCase();
    return lots.where((lot) {
      return lot.name.toLowerCase().contains(lowerQuery) ||
          lot.address.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

class ParkingLotsNotifier extends StateNotifier<ParkingLotsState> {
  final GetParkingLotsUseCase getParkingLotsUseCase;
  Timer? _debounce;

  ParkingLotsNotifier(this.getParkingLotsUseCase) 
      : super(const ParkingLotsState()) {
    Future.microtask(() => loadParkingLots());
  }

  Future<void> loadParkingLots() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getParkingLotsUseCase();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (lots) {
        state = state.copyWith(isLoading: false, lots: lots);
      },
    );
  }

  void setSearchQuery(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
    });
  }

  Future<void> refresh() async {
    await loadParkingLots();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// Main parking lots provider
final parkingLotsProvider =
    StateNotifierProvider<ParkingLotsNotifier, ParkingLotsState>((ref) {
  return ParkingLotsNotifier(ref.read(getParkingLotsUseCaseProvider));
});

// Tab index provider for Lista/Mapa toggle
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

// Slots provider for a specific lot
final parkingSlotsProvider = FutureProvider.family<List<ParkingSlot>, int>((ref, lotId) async {
  final dataSource = ref.read(parkingRemoteDataSourceProvider);
  return await dataSource.getSlotsByLot(lotId);
});

// User location provider
final userLocationProvider = StateNotifierProvider<UserLocationNotifier, LatLng?>((ref) {
  return UserLocationNotifier();
});

class UserLocationNotifier extends StateNotifier<LatLng?> {
  UserLocationNotifier() : super(null) {
    updateLocation();
  }

  Future<void> updateLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      state = LatLng(position.latitude, position.longitude);
    }
  }
}

