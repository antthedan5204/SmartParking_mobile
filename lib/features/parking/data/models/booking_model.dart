import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.slotId,
    required super.vehicleId,
    required super.startTime,
    required super.endTime,
    required super.status,
    required super.totalPrice,
    super.lotName,
    super.slotNumber,
    super.vehiclePlateNumber,
    super.penaltyFee,
    super.actualCheckoutTime,
    super.extensionFee,
    super.extensionTime,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      slotId: json['slotId'] ?? 0,
      vehicleId: json['vehicleId'] ?? 0,
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      status: _parseStatus(json['status']),
      totalPrice: ((json['totalPrice'] ?? 0) as num).toDouble(),
      penaltyFee: ((json['penaltyFee'] ?? json['PenaltyFee'] ?? 0) as num).toDouble(),
      extensionFee: ((json['extensionFee'] ?? json['ExtensionFee'] ?? 0) as num).toDouble(),
      extensionTime: json['extensionTime'] ?? json['ExtensionTime'],
      actualCheckoutTime: (json['actualCheckoutTime'] ?? json['ActualCheckoutTime']) != null 
          ? _parseDateTime(json['actualCheckoutTime'] ?? json['ActualCheckoutTime']) 
          : null,
      lotName: json['parkingLotName'] ?? 
               json['parkingSlot']?['parkingLot']?['name'] ?? 
               json['lotName'],
      slotNumber: json['slotNumber'] ?? 
                  json['parkingSlot']?['slotNumber'],
      vehiclePlateNumber: json['vehicle']?['plateNumber'] ?? 
                          json['vehicle']?['licensePlate'] ?? 
                          json['vehiclePlateNumber'],
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      String dateStr = value.toString();
      // Force UTC interpretation by ensuring 'Z' is present
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        dateStr = '${dateStr.replaceAll(' ', 'T')}Z';
      }
      return DateTime.parse(dateStr).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  static BookingStatus _parseStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0: return BookingStatus.pending;
        case 1: return BookingStatus.confirmed;
        case 2: return BookingStatus.completed;
        case 3: return BookingStatus.cancelled;
        case 4: return BookingStatus.checkedIn;
        default: return BookingStatus.confirmed;
      }
    } else if (status is String) {
      switch (status.toLowerCase()) {
        case 'pending': return BookingStatus.pending;
        case 'confirmed': return BookingStatus.confirmed;
        case 'completed': return BookingStatus.completed;
        case 'cancelled': return BookingStatus.cancelled;
        case 'checkedin':
        case 'checked_in': return BookingStatus.checkedIn;
        default: return BookingStatus.confirmed;
      }
    }
    return BookingStatus.confirmed;
  }

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'vehicleId': vehicleId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }
}
