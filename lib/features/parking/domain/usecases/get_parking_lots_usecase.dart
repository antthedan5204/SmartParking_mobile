import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/parking_lot.dart';
import '../repositories/parking_repository.dart';

class GetParkingLotsUseCase {
  final ParkingRepository repository;

  GetParkingLotsUseCase(this.repository);

  Future<Either<Failure, List<ParkingLot>>> call() {
    return repository.getParkingLots();
  }
}
