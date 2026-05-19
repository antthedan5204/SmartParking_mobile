import 'package:equatable/equatable.dart';

enum PaymentMethod {
  momo,
  vnpay,
  cash
}

enum PaymentStatus {
  pending,
  success,
  failed
}

class Payment extends Equatable {
  final int id;
  final int bookingId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, bookingId, amount, method, status, transactionId, createdAt
  ];
}
