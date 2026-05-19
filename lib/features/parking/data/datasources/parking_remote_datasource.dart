import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/parking_lot_model.dart';
import '../models/parking_slot_model.dart';
import '../models/booking_model.dart';
import '../models/payment_model.dart';
import '../../domain/entities/vehicle.dart';

class ParkingRemoteDataSource {
  final Dio dio;

  ParkingRemoteDataSource(this.dio);

  Future<List<ParkingLotModel>> getParkingLots() async {
    try {
      final response = await dio.get(ApiEndpoints.parkingLots);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          if (data is List) {
            return data.map((json) => ParkingLotModel.fromJson(json)).toList();
          }
        }
        return [];
      }
      throw ServerException(message: 'Failed to load parking lots');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to load parking lots',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ParkingLotModel> getParkingLotById(int id) async {
    try {
      final response = await dio.get(ApiEndpoints.parkingLotById(id));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return ParkingLotModel.fromJson(responseData['data']);
        }
      }
      throw ServerException(message: 'Parking lot not found');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to load parking lot',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<ParkingSlotModel>> getSlotsByLot(int lotId) async {
    try {
      final response = await dio.get(ApiEndpoints.parkingSlotsByLot(lotId));
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Case 1: Wrapped in { "success": true, "data": [...] }
        if (responseData is Map<String, dynamic> && responseData['success'] == true) {
          final data = responseData['data'];
          if (data is List) {
            return data.map((json) => ParkingSlotModel.fromJson(json)).toList();
          }
        }
        
        // Case 2: List returned directly
        if (responseData is List) {
          return responseData.map((json) => ParkingSlotModel.fromJson(json)).toList();
        }
        
        // Case 3: Wrapped in { "data": [...] } but no success field
        if (responseData is Map<String, dynamic> && responseData['data'] is List) {
          final data = responseData['data'];
          return data.map((json) => ParkingSlotModel.fromJson(json)).toList();
        }
        
        return [];
      }
      throw ServerException(message: 'Failed to load slots');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to load slots',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<BookingModel> createBooking({
    required int slotId,
    required int vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.bookings,
        data: {
          'slotId': slotId,
          'vehicleId': vehicleId,
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return BookingModel.fromJson(responseData['data']);
        }
      }
      throw ServerException(message: 'Failed to create booking');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to create booking',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<PaymentModel> createPayment({
    required int bookingId,
    required double amount,
    required int paymentMethod,
    String? transactionId,
  }) async {
    try {
      // Map the int index back to a string that the backend understands
      // 0: MoMo, 1: VNPay, 2: Cash based on current enum order
      String methodString;
      switch (paymentMethod) {
        case 0: methodString = "MoMo"; break;
        case 1: methodString = "VNPay"; break;
        case 2: methodString = "Cash"; break;
        default: methodString = "Cash";
      }

      final response = await dio.post(
        ApiEndpoints.payments,
        data: {
          'bookingId': bookingId,
          'amount': amount,
          'paymentMethod': methodString,
          if (transactionId != null) 'transactionId': transactionId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return PaymentModel.fromJson(responseData['data']);
        }
      }
      throw ServerException(message: 'Failed to process payment');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to process payment',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<BookingModel>> getUserBookings() async {
    try {
      final response = await dio.get(ApiEndpoints.bookings);
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        List<dynamic>? rawList;
        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true || responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is List) rawList = data;
          }
        } else if (responseData is List) {
          rawList = responseData;
        }

        if (rawList != null) {
          return rawList.map((json) {
            try {
              return BookingModel.fromJson(json);
            } catch (e) {
              return null;
            }
          }).whereType<BookingModel>().toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to load bookings',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<VehicleModel>> getUserVehicles() async {
    try {
      final response = await dio.get(ApiEndpoints.vehicles);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          if (data is List) {
            return data.map((json) => VehicleModel.fromJson(json)).toList();
          }
        }
      }
      return [];
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to load vehicles',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<ParkingSlotModel>> getAvailableSlots(int lotId) async {
    final slots = await getSlotsByLot(lotId);
    return slots.where((s) => s.status == 'Available' || s.status == 'available' || s.status == '0').toList();
  }

  Future<VehicleModel> addVehicle({
    required String plateNumber,
    required String type,
    String? color,
    String? brand,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.vehicles,
        data: {
          'PlateNumber': plateNumber,
          'Type': type,
          if (color != null) 'Color': color,
          if (brand != null) 'Brand': brand,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return VehicleModel.fromJson(responseData['data']);
        }
      }
      throw ServerException(message: 'Failed to add vehicle');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to add vehicle',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      final response = await dio.delete('${ApiEndpoints.vehicles}/$id');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return;
        }
      }
      throw ServerException(message: 'Failed to delete vehicle');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to delete vehicle',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> cancelBooking(int id) async {
    try {
      final response = await dio.patch(ApiEndpoints.cancelBooking(id));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return;
        }
      }
      throw ServerException(message: 'Failed to cancel booking');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to cancel booking',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<BookingModel> extendBooking({
    required int bookingId,
    required DateTime newEndTime,
  }) async {
    try {
      final response = await dio.put(
        ApiEndpoints.bookingById(bookingId),
        data: {
          'endTime': newEndTime.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return BookingModel.fromJson(responseData['data']);
        }
      }
      throw ServerException(message: 'Failed to extend booking');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to extend booking',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> checkInBooking(int id) async {
    try {
      await dio.patch(ApiEndpoints.checkinBooking(id));
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to check-in',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> completeBooking(int id) async {
    try {
      await dio.patch(ApiEndpoints.completeBooking(id));
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to complete booking',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> updateSlotStatus(int id, String status) async {
    try {
      await dio.patch(
        ApiEndpoints.parkingSlotStatus(id),
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to update slot status',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
