import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../parking/presentation/providers/parking_provider.dart';

class ManageSlotsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ManageSlotsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> updateSlotStatus(int slotId, String status, int lotId) async {
    state = const AsyncLoading();
    
    final repository = ref.read(parkingRepositoryProvider);
    final result = await repository.updateSlotStatus(slotId, status);

    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        // Refresh the slots of this lot
        ref.invalidate(parkingSlotsProvider(lotId));
        // Refresh the general parking lots list to update remaining spots count
        ref.read(parkingLotsProvider.notifier).refresh();
        return true;
      },
    );
  }

  Future<bool> bookOnBehalf({
    required int slotId,
    required int lotId,
    required String plateNumber,
    required int durationHours,
  }) async {
    state = const AsyncLoading();
    try {
      final remoteDataSource = ref.read(parkingRemoteDataSourceProvider);
      
      // 1. Get or create vehicle
      final vehiclesResult = await remoteDataSource.getUserVehicles();
      int? vehicleId;
      for (final v in vehiclesResult) {
        if (v.licensePlate.replaceAll('-', '').replaceAll(' ', '').toLowerCase() == 
            plateNumber.replaceAll('-', '').replaceAll(' ', '').toLowerCase()) {
          vehicleId = v.id;
          break;
        }
      }
      
      if (vehicleId == null) {
        final newVehicle = await remoteDataSource.addVehicle(
          plateNumber: plateNumber.toUpperCase(),
          type: 'Car',
        );
        vehicleId = newVehicle.id;
      }
      
      // 2. Create booking (add 5 minutes buffer to satisfy backend validation "startTime must be in the future")
      final now = DateTime.now().add(const Duration(minutes: 5));
      final booking = await remoteDataSource.createBooking(
        slotId: slotId,
        vehicleId: vehicleId,
        startTime: now,
        endTime: now.add(Duration(hours: durationHours)),
      );
      
      // 3. Immediately Check-In the booking to set slot status to Occupied
      await remoteDataSource.dio.patch(
        ApiEndpoints.checkinBooking(booking.id),
      );
      
      state = const AsyncValue.data(null);
      // Invalidate providers to trigger instant UI updates
      ref.invalidate(parkingSlotsProvider(lotId));
      ref.read(parkingLotsProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<bool> checkoutVehicle(int bookingId, int lotId) async {
    state = const AsyncLoading();
    try {
      final remoteDataSource = ref.read(parkingRemoteDataSourceProvider);
      final result = await remoteDataSource.dio.patch(
        ApiEndpoints.completeBooking(bookingId),
      );
      
      if (result.statusCode == 200) {
        state = const AsyncValue.data(null);
        ref.invalidate(parkingSlotsProvider(lotId));
        ref.read(parkingLotsProvider.notifier).refresh();
        return true;
      } else {
        state = AsyncError('Không thể hoàn thành đơn đặt chỗ', StackTrace.current);
        return false;
      }
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
      return false;
    }
  }
}

final manageSlotsProvider = StateNotifierProvider<ManageSlotsNotifier, AsyncValue<void>>((ref) {
  return ManageSlotsNotifier(ref);
});
