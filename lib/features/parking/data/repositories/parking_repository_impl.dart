import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/parking_lot.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/parking_repository.dart';
import '../datasources/parking_remote_datasource.dart';

class ParkingRepositoryImpl implements ParkingRepository {
  final ParkingRemoteDataSource remoteDataSource;

  ParkingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ParkingLot>>> getParkingLots() async {
    try {
      final lots = await remoteDataSource.getParkingLots();
      return Right(lots);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParkingLot>> getParkingLotById(int id) async {
    try {
      final lot = await remoteDataSource.getParkingLotById(id);
      return Right(lot);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParkingSlot>>> getSlotsByLot(int lotId) async {
    try {
      final slots = await remoteDataSource.getSlotsByLot(lotId);
      return Right(slots);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Booking>> createBooking({
    required int slotId,
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final booking = await remoteDataSource.createBooking(
        slotId: slotId,
        vehicleId: vehicleId,
        startTime: startTime,
        endTime: endTime,
      );
      return Right(booking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getUserBookings() async {
    try {
      final bookings = await remoteDataSource.getUserBookings();
      return Right(bookings);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> createPayment({
    required int bookingId,
    required double amount,
    required int paymentMethod,
    String? transactionId,
  }) async {
    try {
      final payment = await remoteDataSource.createPayment(
        bookingId: bookingId,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );
      return Right(payment);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getUserVehicles() async {
    try {
      final vehicles = await remoteDataSource.getUserVehicles();
      return Right(vehicles);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Vehicle>> addVehicle({
    required String licensePlate,
    required String model,
    String? color,
    String? brand,
  }) async {
    try {
      final vehicle = await remoteDataSource.addVehicle(
        plateNumber: licensePlate,
        type: model,
        color: color,
        brand: brand,
      );
      return Right(vehicle);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVehicle(int id) async {
    try {
      await remoteDataSource.deleteVehicle(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(int id) async {
    try {
      await remoteDataSource.cancelBooking(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> checkInBooking(int id) async {
    try {
      await remoteDataSource.checkInBooking(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completeBooking(int id) async {
    try {
      await remoteDataSource.completeBooking(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Booking>> extendBooking({
    required int bookingId,
    required DateTime newEndTime,
  }) async {
    try {
      final booking = await remoteDataSource.extendBooking(
        bookingId: bookingId,
        newEndTime: newEndTime,
      );
      return Right(booking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSlotStatus(int slotId, String status) async {
    try {
      await remoteDataSource.updateSlotStatus(slotId, status);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
