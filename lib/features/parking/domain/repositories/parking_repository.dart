import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/parking_lot.dart';
import '../entities/parking_slot.dart';
import '../entities/booking.dart';
import '../entities/payment.dart';
import '../entities/vehicle.dart';

abstract class ParkingRepository {
  Future<Either<Failure, List<ParkingLot>>> getParkingLots();
  Future<Either<Failure, ParkingLot>> getParkingLotById(int id);
  Future<Either<Failure, List<ParkingSlot>>> getSlotsByLot(int lotId);
  Future<Either<Failure, Booking>> createBooking({
    required int slotId,
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  });
  Future<Either<Failure, List<Booking>>> getUserBookings();
  Future<Either<Failure, Payment>> createPayment({
    required int bookingId,
    required double amount,
    required int paymentMethod,
    String? transactionId,
  });
  Future<Either<Failure, List<Vehicle>>> getUserVehicles();
  Future<Either<Failure, Vehicle>> addVehicle({
    required String licensePlate,
    required String model,
    String? color,
    String? brand,
  });
  Future<Either<Failure, void>> deleteVehicle(int id);
  Future<Either<Failure, void>> cancelBooking(int id);
  Future<Either<Failure, void>> checkInBooking(int id);
  Future<Either<Failure, void>> completeBooking(int id);
  Future<Either<Failure, Booking>> extendBooking({
    required int bookingId,
    required DateTime newEndTime,
  });
  Future<Either<Failure, void>> updateSlotStatus(int slotId, String status);
}
