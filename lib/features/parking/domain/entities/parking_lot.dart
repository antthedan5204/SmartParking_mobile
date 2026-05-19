import 'package:equatable/equatable.dart';

class ParkingLot extends Equatable {
  final int id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final int totalSlots;
  final double pricePerHour;
  final int? availableSlots;
  final int? managerId;
  final bool? hasEvStation;

  const ParkingLot({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.totalSlots,
    required this.pricePerHour,
    this.availableSlots,
    this.managerId,
    this.hasEvStation,
  });

  int get occupiedSlots => totalSlots - (availableSlots ?? 0);

  double get occupancyPercent {
    if (totalSlots == 0) return 0;
    return occupiedSlots / totalSlots;
  }

  String get occupancyDisplay =>
      '${availableSlots ?? 0}/$totalSlots';

  @override
  List<Object?> get props => [
        id, name, address, latitude, longitude,
        totalSlots, pricePerHour, availableSlots, managerId, hasEvStation,
      ];
}
