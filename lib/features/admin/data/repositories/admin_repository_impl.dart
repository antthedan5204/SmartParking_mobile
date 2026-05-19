import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../parking/domain/entities/booking.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<User>>> getAllUsers() async {
    try {
      final users = await remoteDataSource.getAllUsers();
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getAllBookings() async {
    try {
      final bookings = await remoteDataSource.getAllBookings();
      return Right(bookings);
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
  Future<Either<Failure, User>> createStaff({
    required String name,
    required String email,
    required String password,
    String? phone,
    required int role,
  }) async {
    try {
      final user = await remoteDataSource.createStaff(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createParkingLot({
    required String name,
    required String address,
    required int totalSlots,
    required double pricePerHour,
    double? latitude,
    double? longitude,
    int? managerId,
    bool? hasEvStation,
  }) async {
    try {
      await remoteDataSource.createParkingLot(
        name: name,
        address: address,
        totalSlots: totalSlots,
        pricePerHour: pricePerHour,
        latitude: latitude,
        longitude: longitude,
        managerId: managerId,
        hasEvStation: hasEvStation,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      await remoteDataSource.updateParkingLot(
        id: id,
        name: name,
        address: address,
        totalSlots: totalSlots,
        pricePerHour: pricePerHour,
        latitude: latitude,
        longitude: longitude,
        managerId: managerId,
        hasEvStation: hasEvStation,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteParkingLot(int id) async {
    try {
      await remoteDataSource.deleteParkingLot(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
