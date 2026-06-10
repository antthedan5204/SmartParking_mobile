import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment.dart';
import '../providers/booking_provider.dart';

class ExtendBookingDialog extends ConsumerStatefulWidget {
  final Booking booking;

  const ExtendBookingDialog({super.key, required this.booking});

  @override
  ConsumerState<ExtendBookingDialog> createState() =>
      _ExtendBookingDialogState();
}

class _ExtendBookingDialogState extends ConsumerState<ExtendBookingDialog> {
  late DateTime _newEndTime;
  PaymentMethod _selectedMethod = PaymentMethod.momo;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _newEndTime = widget.booking.endTime.add(const Duration(hours: 1));
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _newEndTime,
      firstDate: widget.booking.endTime,
      lastDate: widget.booking.endTime.add(const Duration(days: 7)),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_newEndTime),
      );
      if (pickedTime != null) {
        final newTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (newTime.isAfter(widget.booking.endTime)) {
          setState(() {
            _newEndTime = newTime;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.translate('newTimeMustBeAfterCurrentTime'),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic price calculation (simplified)
    // In real app, we might want to fetch lot price or use a fixed rate
    const double pricePer30Min = 10000;
    final int extraMinutes = _newEndTime
        .difference(widget.booking.endTime)
        .inMinutes;
    final int extraPricePeriods = (extraMinutes / 30).ceil();
    final double extraAmount = extraPricePeriods > 0
        ? extraPricePeriods * pricePer30Min
        : 0;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.translate('extendBookingTitle')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.translate('currentTime')}: ${widget.booking.endTime.hour}:${widget.booking.endTime.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('selectNewCheckoutTime'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDateTime,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('estimatedCheckoutTime'),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm, dd/MM/yyyy').format(_newEndTime),
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.edit_calendar_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 32),
            Text(
              l10n.translate('paymentMethodLabel'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              PaymentMethod.momo,
              'MoMo',
              Icons.account_balance_wallet_rounded,
              const Color(0xFFA50064),
            ),
            _buildPaymentOption(
              PaymentMethod.vnpay,
              'VNPay',
              Icons.payment_rounded,
              const Color(0xFF005BAA),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.translate('extendedDuration')),
                Text(
                  '$extraMinutes ${l10n.translate('minutesAbbr')}',
                  style: AppTextStyles.subtitle2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.translate('extraFee')),
                Text(
                  '${extraAmount.toStringAsFixed(0)} ${l10n.translate('currencyShort')}',
                  style: AppTextStyles.subtitle2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: Text(l10n.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () async {
                  setState(() => _isProcessing = true);
                  // Giả lập thời gian kết nối cổng thanh toán 2 giây
                  await Future.delayed(const Duration(seconds: 2));

                  if (!mounted) return;

                  final success = await ref
                      .read(bookingProvider.notifier)
                      .extendBooking(
                        bookingId: widget.booking.id,
                        newEndTime: _newEndTime,
                        extraAmount: extraAmount,
                        method: _selectedMethod,
                      );

                  if (mounted) {
                    setState(() => _isProcessing = false);
                  }

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.translate('extendSuccess'))),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.translate('confirmBtn')),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    String name,
    IconData icon,
    Color color,
  ) {
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
