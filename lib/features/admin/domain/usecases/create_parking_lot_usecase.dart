import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class CreateParkingLotUseCase {
  final AdminRepository repository;

  CreateParkingLotUseCase(this.repository);

  Future<Either<Failure, void>> call(CreateParkingLotParams params) async {
    return await repository.createParkingLot(
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

class CreateParkingLotParams extends Equatable {
  final String name;
  final String address;
  final int totalSlots;
  final double pricePerHour;
  final double? latitude;
  final double? longitude;
  final int? managerId;
  final bool? hasEvStation;

  const CreateParkingLotParams({
    required this.name,
    required this.address,
    required this.totalSlots,
    required this.pricePerHour,
    this.latitude,
    this.longitude,
    this.managerId,
    this.hasEvStation,
  });

  @override
  List<Object?> get props => [
    name,
    address,
    totalSlots,
    pricePerHour,
    latitude,
    longitude,
    managerId,
    hasEvStation,
  ];
}
