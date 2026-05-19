import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../parking/domain/entities/booking.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<User>>> getAllUsers();
  Future<Either<Failure, List<Booking>>> getAllBookings();
  Future<Either<Failure, void>> checkInBooking(int id);
  Future<Either<Failure, void>> completeBooking(int id);

  Future<Either<Failure, User>> createStaff({
    required String name,
    required String email,
    required String password,
    String? phone,
    required int role,
  });

  Future<Either<Failure, void>> createParkingLot({
    required String name,
    required String address,
    required int totalSlots,
    required double pricePerHour,
    double? latitude,
    double? longitude,
    int? managerId,
    bool? hasEvStation,
  });

  Future<Either<Failure, void>> updateParkingLot({
    required int id,
    required String name,
    required String address,
    required int totalSlots,
    required double pricePerHour,
    double? latitude,
    double? longitude,
    int? managerId,
    bool? hasEvStation,
  });

  Future<Either<Failure, void>> deleteParkingLot(int id);
}
