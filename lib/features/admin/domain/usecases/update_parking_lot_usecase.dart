import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class UpdateParkingLotUseCase {
  final AdminRepository repository;

  UpdateParkingLotUseCase(this.repository);

  Future<Either<Failure, void>> call(UpdateParkingLotParams params) async {
    return await repository.updateParkingLot(
      id: params.id,
      name: params.name,
      address: params.address,
      totalSlots: params.totalSlots,
      pricePerHour: params.pricePerHour,
      latitude: params.latitude,
      longitude: params.longitude,
      managerId: params.managerId,
      hasEvStation: params.hasEvStation,
    );
  }
}

class UpdateParkingLotParams {
  final int id;
  final String name;
  final String address;
  final int totalSlots;
  final double pricePerHour;
  final double? latitude;
  final double? longitude;
  final int? managerId;
  final bool? hasEvStation;

  UpdateParkingLotParams({
    required this.id,
    required this.name,
    required this.address,
    required this.totalSlots,
    required this.pricePerHour,
    this.latitude,
    this.longitude,
    this.managerId,
    this.hasEvStation,
  });
}
