import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../parking/data/models/booking_model.dart';

class AdminRemoteDataSource {
  final Dio dio;

  AdminRemoteDataSource(this.dio);

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await dio.get(ApiEndpoints.users);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          if (data is List) {
            return data.map((json) => UserModel.fromJson(json)).toList();
          }
        }
        return [];
      }
      throw ServerException(message: 'Failed to load users');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to load users',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<UserModel> createStaff({
    required String name,
    required String email,
    required String password,
    String? phone,
    required int role, // 1 for Manager, 2 for Admin based on backend enum
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.createStaff,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
          'role': role,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return UserModel.fromJson(responseData['data']);
        }
        throw ServerException(message: responseData['message'] ?? 'Failed to create staff');
      }
      throw ServerException(message: 'Failed to create staff');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to create staff',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> createParkingLot({
    required String name,
    required String address,
    required int totalSlots,
    required double pricePerHour,
    double? latitude,
    double? longitude,
    int? managerId,
    bool? hasEvStation,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.parkingLots,
        data: {
          'name': name,
          'address': address,
          'totalSlots': totalSlots,
          'pricePerHour': pricePerHour,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (managerId != null) 'managerId': managerId,
          if (hasEvStation != null) 'hasEvStation': hasEvStation,
        },
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final Map<String, dynamic> responseData = response.data;
        throw ServerException(message: responseData['message'] ?? 'Failed to create parking lot');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to create parking lot',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> updateParkingLot({
    required int id,
    required String name,
    required String address,
    required int totalSlots,
    required double pricePerHour,
    double? latitude,
    double? longitude,
    int? managerId,
    bool? hasEvStation,
  }) async {
    try {
      final data = {
        'name': name,
        'address': address,
        'totalSlots': totalSlots,
        'pricePerHour': pricePerHour,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (managerId != null) 'managerId': managerId,
        if (hasEvStation != null) 'hasEvStation': hasEvStation,
      };
      
      debugPrint('[AdminRemoteDataSource] PUT /api/parking-lots/$id data: $data');

      final response = await dio.put(
        '${ApiEndpoints.parkingLots}/$id',
        data: data,
      );

      if (response.statusCode != 200) {
        throw ServerException(message: 'Failed to update parking lot');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to update parking lot',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> deleteParkingLot(int id) async {
    try {
      final response = await dio.delete(
        '${ApiEndpoints.parkingLots}/$id',
      );

      if (response.statusCode != 200) {
        throw ServerException(message: 'Failed to delete parking lot');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to delete parking lot',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<BookingModel>> getAllBookings() async {
    try {
      final response = await dio.get(ApiEndpoints.allBookings);
      debugPrint('DIO: GET ${ApiEndpoints.allBookings} - Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        List<dynamic>? rawList;
        
        // Case 1: Wrapped in { "success": true, "data": [...] }
        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true || responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is List) {
              rawList = data;
            }
          }
        }
        
        // Case 2: List returned directly
        if (responseData is List) {
          rawList = responseData;
        }
        
        if (rawList != null) {
          return rawList.map((json) {
            try {
              return BookingModel.fromJson(json);
            } catch (e) {
              debugPrint('Error parsing booking: $e');
              return null;
            }
          }).whereType<BookingModel>().toList();
        }
        
        return [];
      }
      throw ServerException(message: 'Failed to load bookings');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to load bookings',
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
}
