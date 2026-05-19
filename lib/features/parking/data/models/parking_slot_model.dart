import '../../../../core/utils/data_utils.dart';
import '../../domain/entities/parking_slot.dart';

class ParkingSlotModel extends ParkingSlot {
  const ParkingSlotModel({
    required super.id,
    required super.lotId,
    required super.slotNumber,
    required super.status,
    super.isEvCharging = false,
  });

  factory ParkingSlotModel.fromJson(Map<String, dynamic> json) {
    // Map integer status from backend to String for frontend
    final rawStatus = DataUtils.parseString(json['status'] ?? json['Status']);
    String statusStr = 'Available';
    
    if (rawStatus == '0' || rawStatus.toLowerCase() == 'available') {
      statusStr = 'Available';
    } else if (rawStatus == '1' || rawStatus.toLowerCase() == 'occupied') {
      statusStr = 'Occupied';
    } else if (rawStatus == '2' || rawStatus.toLowerCase() == 'maintenance') {
      statusStr = 'Maintenance';
    }

    return ParkingSlotModel(
      id: DataUtils.toInt(json['id'] ?? json['Id']),
      lotId: DataUtils.toInt(json['lotId'] ?? json['LotId']),
      slotNumber: DataUtils.parseString(json['slotNumber'] ?? json['SlotNumber']),
      status: statusStr,
      isEvCharging: json['isEvCharging'] ?? json['IsEvCharging'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lotId': lotId,
      'slotNumber': slotNumber,
      'status': status,
      'isEvCharging': isEvCharging,
    };
  }
}
