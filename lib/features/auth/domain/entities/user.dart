import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? token;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.token,
  });

  bool get isAdmin =>
      role.toLowerCase().contains('admin') ||
      role.toLowerCase().contains('administrator');
  bool get isManager => role.toLowerCase().contains('manager');

  @override
  List<Object?> get props => [id, name, email, role, phone, token];
}
