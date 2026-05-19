import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../parking/domain/entities/booking.dart';

class GetAllBookingsUseCase {
  final AdminRepository repository;

  GetAllBookingsUseCase(this.repository);

  Future<Either<Failure, List<Booking>>> call() async {
    return await repository.getAllBookings();
  }
}
