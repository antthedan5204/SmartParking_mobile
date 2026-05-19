import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.phone,
    super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    // If the input is the full ApiResponse, extract 'data'
    final Map<String, dynamic> data =
        (json.containsKey('success') && json['data'] is Map<String, dynamic>)
            ? json['data'] as Map<String, dynamic>
            : json;

    // If the data contains a 'user' key, use that
    final Map<String, dynamic> userData = (data['user'] is Map<String, dynamic>)
        ? data['user'] as Map<String, dynamic>
        : data;

    return UserModel(
      id: userData['id'] ?? userData['userId'] ?? data['userId'] ?? 0,
      name: userData['name'] ?? userData['fullName'] ?? data['fullName'] ?? '',
      email: userData['email'] ?? '',
      role: userData['role'] ??
          userData['Role'] ??
          userData['userRole'] ??
          data['role'] ??
          'User',
      phone: userData['phone'],
      token: token ?? data['token'] ?? json['token'] ?? userData['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'token': token,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      token: token ?? this.token,
    );
  }
}
