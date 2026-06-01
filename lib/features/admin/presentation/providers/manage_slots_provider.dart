import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../parking/presentation/providers/parking_provider.dart';
import '../../../parking/data/models/booking_model.dart';

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

  Future<Map<String, dynamic>?> bookOnBehalf({
    required int slotId,
    required int lotId,
    required String plateNumber,
    required int durationHours,
    required double amount,
    required String lotName,
    required String slotNumber,
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
      
      // 3. Create payment (Cash)
      final payment = await remoteDataSource.createPayment(
        bookingId: booking.id,
        amount: amount,
        paymentMethod: 2, // Cash
        transactionId: 'CASH_${DateTime.now().millisecondsSinceEpoch}',
      );

      // 4. Immediately Check-In the booking to set slot status to Occupied
      await remoteDataSource.dio.patch(
        ApiEndpoints.checkinBooking(booking.id),
      );
      
      final enrichedBooking = BookingModel(
        id: booking.id,
        userId: booking.userId,
        slotId: booking.slotId,
        vehicleId: booking.vehicleId,
        startTime: booking.startTime,
        endTime: booking.endTime,
        status: booking.status,
        totalPrice: booking.totalPrice,
        lotName: lotName,
        slotNumber: slotNumber,
        vehiclePlateNumber: plateNumber,
      );

      state = const AsyncValue.data(null);
      // Invalidate providers to trigger instant UI updates
      ref.invalidate(parkingSlotsProvider(lotId));
      ref.read(parkingLotsProvider.notifier).refresh();
      return {'booking': enrichedBooking, 'payment': payment};
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
      return null;
    }
  }

  Future<bool> checkoutVehicle(int bookingId, int lotId, int slotId) async {
    state = const AsyncLoading();
    try {
      final remoteDataSource = ref.read(parkingRemoteDataSourceProvider);
      final result = await remoteDataSource.dio.patch(
        ApiEndpoints.completeBooking(bookingId),
      );
      
      if (result.statusCode == 200 || result.statusCode == 204) {
        // Explicitly set the slot status back to Available
        final repository = ref.read(parkingRepositoryProvider);
        await repository.updateSlotStatus(slotId, 'Available');
        
        state = const AsyncValue.data(null);
        ref.invalidate(parkingSlotsProvider(lotId));
        ref.read(parkingLotsProvider.notifier).refresh();
        return true;
      } else {
        state = AsyncError('bookingFailed', StackTrace.current);
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
