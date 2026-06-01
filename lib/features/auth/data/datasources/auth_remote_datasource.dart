import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource(this.dio);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          final token = data['token'] ?? data['accessToken'] ?? '';
          return UserModel.fromJson(data, token: token);
        }
        throw ServerException(
          message: responseData['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
      throw ServerException(
        message: response.data?['message'] ?? 'Login failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'wrongCredentials',
          statusCode: e.response?.statusCode,
        );
      }
      throw ServerException(
        message: e.message ?? 'Server error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<UserModel> googleLogin({required String idToken}) async {
    try {
      final response = await dio.post(
        ApiEndpoints.googleLogin,
        data: {'idToken': idToken},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          final token = data['token'] ?? data['accessToken'] ?? '';
          return UserModel.fromJson(data, token: token);
        }
        throw ServerException(
          message: responseData['message'] ?? 'Google login failed',
          statusCode: response.statusCode,
        );
      }
      throw ServerException(
        message: response.data?['message'] ?? 'Google login failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Google login failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            return UserModel.fromJson(data);
          }
        }
        // If registration returns just a success message, create a basic model
        return UserModel(
          id: 0,
          name: name,
          email: email,
          role: 'User',
          phone: phone,
        );
      }
      throw ServerException(
        message: response.data?['message'] ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Registration failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(ApiEndpoints.userProfile);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return UserModel.fromJson(responseData['data']);
        }
      }
      throw ServerException(message: 'Failed to get profile');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to get profile',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<UserModel> updateProfile({
    required int id,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await dio.put(
        ApiEndpoints.userById(id),
        data: {
          'name': name,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return UserModel.fromJson(responseData['data']);
        }
      }
      throw ServerException(
        message: response.data?['message'] ?? 'Failed to update profile',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to update profile',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<bool> sendForgotPasswordEmail(String email) async {
    try {
      final response = await dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to send reset email',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<bool> verifyResetToken({
    required String email,
    required String token,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.verifyResetToken,
        data: {
          'email': email,
          'token': token,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'invalidOtp',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'token': token,
          'newPassword': newPassword,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to reset password',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<bool> sendVerificationEmail(String email) async {
    try {
      final response = await dio.post(
        ApiEndpoints.sendVerificationEmail,
        data: {'email': email},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Gửi email xác thực thất bại',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<UserModel> verifyEmail({
    required String email,
    required String token,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.verifyEmail,
        data: {
          'email': email,
          'token': token,
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          final jwtToken = data['token'] ?? data['accessToken'] ?? '';
          return UserModel.fromJson(data, token: jwtToken);
        }
        throw ServerException(
          message: responseData['message'] ?? 'Xác thực thất bại',
          statusCode: response.statusCode,
        );
      }
      throw ServerException(
        message: response.data?['message'] ?? 'Xác thực thất bại',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'invalidOtp',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
