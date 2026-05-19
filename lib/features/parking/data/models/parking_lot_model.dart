
import '../../../../core/utils/data_utils.dart';
import '../../domain/entities/parking_lot.dart';

class ParkingLotModel extends ParkingLot {
  const ParkingLotModel({
    required super.id,
    required super.name,
    required super.address,
    super.latitude,
    super.longitude,
    required super.totalSlots,
    required super.pricePerHour,
    super.availableSlots,
    super.managerId,
    super.hasEvStation,
  });

  factory ParkingLotModel.fromJson(Map<String, dynamic> json) {
    return ParkingLotModel(
      id: DataUtils.toInt(json['id'] ?? json['Id']),
      name: DataUtils.parseString(json['name'] ?? json['Name']),
      address: DataUtils.parseString(json['address'] ?? json['Address']),
      latitude: DataUtils.toDouble(json['latitude'] ?? json['Latitude']),
      longitude: DataUtils.toDouble(json['longitude'] ?? json['Longitude']),
      totalSlots: DataUtils.toInt(json['totalSlots'] ?? json['TotalSlots']),
      pricePerHour: DataUtils.toDouble(json['pricePerHour'] ?? json['PricePerHour']),
      availableSlots: DataUtils.toInt(json['availableSlots'] ?? json['AvailableSlots'], defaultValue: -1) == -1 
          ? null 
          : DataUtils.toInt(json['availableSlots'] ?? json['AvailableSlots']),
      managerId: DataUtils.toInt(json['managerId'] ?? json['ManagerId']),
      hasEvStation: json['hasEvStation'] ?? json['HasEvStation'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'totalSlots': totalSlots,
      'pricePerHour': pricePerHour,
      'managerId': managerId,
      'hasEvStation': hasEvStation,
    };
  }
}
