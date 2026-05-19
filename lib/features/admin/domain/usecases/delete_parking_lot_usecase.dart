import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class DeleteParkingLotUseCase {
  final AdminRepository repository;

  DeleteParkingLotUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) async {
    return await repository.deleteParkingLot(id);
  }
}
