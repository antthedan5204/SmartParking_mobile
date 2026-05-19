import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.bookingId,
    required super.amount,
    required super.method,
    required super.status,
    super.transactionId,
    required super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      bookingId: json['bookingId'],
      amount: (json['amount'] as num).toDouble(),
      method: _mapMethod(json['paymentMethod']),
      status: _mapStatus(json['status']),
      transactionId: json['transactionId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static PaymentMethod _mapMethod(dynamic method) {
    if (method is int) {
      switch (method) {
        case 0: return PaymentMethod.momo;
        case 1: return PaymentMethod.vnpay;
        case 2: return PaymentMethod.cash;
        default: return PaymentMethod.momo;
      }
    } else if (method is String) {
      switch (method.toLowerCase()) {
        case 'momo': return PaymentMethod.momo;
        case 'vnpay': return PaymentMethod.vnpay;
        case 'cash': return PaymentMethod.cash;
        default: return PaymentMethod.momo;
      }
    }
    return PaymentMethod.momo;
  }

  static PaymentStatus _mapStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0: return PaymentStatus.pending;
        case 1: return PaymentStatus.success;
        case 2: return PaymentStatus.failed;
        default: return PaymentStatus.pending;
      }
    } else if (status is String) {
      switch (status.toLowerCase()) {
        case 'pending': return PaymentStatus.pending;
        case 'completed':
        case 'success': return PaymentStatus.success;
        case 'failed': return PaymentStatus.failed;
        default: return PaymentStatus.pending;
      }
    }
    return PaymentStatus.pending;
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'amount': amount,
      'paymentMethod': method.index,
      'transactionId': transactionId,
    };
  }
}
