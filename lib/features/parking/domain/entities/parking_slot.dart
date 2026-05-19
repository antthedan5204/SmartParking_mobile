import 'package:equatable/equatable.dart';

class ParkingSlot extends Equatable {
  final int id;
  final int lotId;
  final String slotNumber;
  final String status; // Available, Occupied, Reserved, etc.
  final bool isEvCharging;

  const ParkingSlot({
    required this.id,
    required this.lotId,
    required this.slotNumber,
    required this.status,
    this.isEvCharging = false,
  });

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isOccupied => status.toLowerCase() == 'occupied';

  @override
  List<Object?> get props => [id, lotId, slotNumber, status, isEvCharging];
}
