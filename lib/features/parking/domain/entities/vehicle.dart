import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  final int id;
  final int userId;
  final String licensePlate;
  final String model; // Mapped from 'Type' in backend
  final String? color;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.licensePlate,
    required this.model,
    this.color,
  });

  @override
  List<Object?> get props => [id, userId, licensePlate, model, color];
}

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.userId,
    required super.licensePlate,
    required super.model,
    super.color,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? json['Id'] ?? 0,
      userId: json['userId'] ?? json['UserId'] ?? 0,
      licensePlate: json['plateNumber'] ?? json['PlateNumber'] ?? json['licensePlate'] ?? '',
      model: json['type'] ?? json['Type'] ?? json['model'] ?? '',
      color: json['color'] ?? json['Color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'PlateNumber': licensePlate,
      'Type': model,
      'color': color,
    };
  }
}
