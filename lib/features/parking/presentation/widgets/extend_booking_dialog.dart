import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment.dart';
import '../providers/booking_provider.dart';

class ExtendBookingDialog extends ConsumerStatefulWidget {
  final Booking booking;

  const ExtendBookingDialog({super.key, required this.booking});

  @override
  ConsumerState<ExtendBookingDialog> createState() => _ExtendBookingDialogState();
}

class _ExtendBookingDialogState extends ConsumerState<ExtendBookingDialog> {
  int _extraMinutes = 30;
  PaymentMethod _selectedMethod = PaymentMethod.momo;

  @override
  Widget build(BuildContext context) {
    // Basic price calculation (simplified)
    // In real app, we might want to fetch lot price or use a fixed rate
    const double pricePer30Min = 10000; 
    final extraAmount = (_extraMinutes / 30) * pricePer30Min;

    return AlertDialog(
      title: const Text('Gia hạn gửi xe'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thời gian hiện tại: ${widget.booking.endTime.hour}:${widget.booking.endTime.minute.toString().padLeft(2, '0')}', 
              style: AppTextStyles.body2),
            const SizedBox(height: 16),
            const Text('Chọn thời gian thêm:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTimeOption(30, '30 phút'),
            _buildTimeOption(60, '1 giờ'),
            _buildTimeOption(120, '2 giờ'),
            
            const Divider(height: 32),
            const Text('Phương thức thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPaymentOption(PaymentMethod.momo, 'MoMo', Icons.account_balance_wallet_rounded, const Color(0xFFA50064)),
            _buildPaymentOption(PaymentMethod.vnpay, 'VNPay', Icons.payment_rounded, const Color(0xFF005BAA)),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Phí phát sinh:'),
                Text('${extraAmount.toStringAsFixed(0)} VNĐ', 
                  style: AppTextStyles.subtitle2.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
        ElevatedButton(
          onPressed: () async {
            final newEndTime = widget.booking.endTime.add(Duration(minutes: _extraMinutes));
            final success = await ref.read(bookingProvider.notifier).extendBooking(
              bookingId: widget.booking.id,
              newEndTime: newEndTime,
              extraAmount: extraAmount,
              method: _selectedMethod,
            );
            
            if (success && mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gia hạn thành công!')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('XÁC NHẬN'),
        ),
      ],
    );
  }

  Widget _buildTimeOption(int minutes, String label) {
    final isSelected = _extraMinutes == minutes;
    return GestureDetector(
      onTap: () => setState(() => _extraMinutes = minutes),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, 
              size: 20, color: isSelected ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.body1),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(PaymentMethod method, String name, IconData icon, Color color) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(name, style: AppTextStyles.body1),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
