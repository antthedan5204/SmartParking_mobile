import 'package:equatable/equatable.dart';

enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  checkedIn
}

class Booking extends Equatable {
  final int id;
  final int userId;
  final int slotId;
  final int vehicleId;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final double totalPrice;
  final String? lotName;
  final String? slotNumber;
  final String? vehiclePlateNumber;
  final double penaltyFee;
  final DateTime? actualCheckoutTime;
  final double extensionFee;
  final int? extensionTime; // in minutes

  const Booking({
    required this.id,
    required this.userId,
    required this.slotId,
    required this.vehicleId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPrice,
    this.lotName,
    this.slotNumber,
    this.vehiclePlateNumber,
    this.penaltyFee = 0.0,
    this.actualCheckoutTime,
    this.extensionFee = 0.0,
    this.extensionTime,
  });

  @override
  List<Object?> get props => [
    id, userId, slotId, vehicleId, startTime, endTime, status, totalPrice, lotName, slotNumber, vehiclePlateNumber, penaltyFee, actualCheckoutTime, extensionFee, extensionTime
  ];
}
