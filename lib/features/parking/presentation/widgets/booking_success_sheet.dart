import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment.dart';
import 'package:intl/intl.dart';

class BookingSuccessSheet extends StatelessWidget {
  final Booking booking;
  final Payment payment;
  final VoidCallback? onDone;

  const BookingSuccessSheet({
    super.key,
    required this.booking,
    required this.payment,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeFormat = DateFormat('HH:mm');

    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Indicator
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
              ),
              const SizedBox(height: 16),
              Text(l10n.translate('paymentSuccessTitle'), style: AppTextStyles.heading2, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(l10n.translate('parkingReadyMessage'), style: AppTextStyles.body2, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              
              // QR Code Section - Wrapped in SizedBox for layout stability
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: QrImageView(
                    data: 'BOOKING:${booking.id}',
                    version: QrVersions.auto,
                    size: 130,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
    
              // Receipt Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildReceiptRow(l10n.translate('receiptId'), '#PK${booking.id.toString().padLeft(6, '0')}'),
                    const Divider(height: 24),
                    _buildReceiptRow(l10n.translate('parkingLot'), booking.lotName ?? ''),
                    _buildReceiptRow(l10n.translate('slotLabel'), '${l10n.translate('slotPrefix') ?? 'Ô số '}${booking.slotNumber ?? booking.slotId}'),
                    _buildReceiptRow(l10n.translate('timeLimit'), '${l10n.translate('until')}${timeFormat.format(booking.endTime.toLocal())}'),
                    _buildReceiptRow(l10n.translate('vehicle'), l10n.translate('car')),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.translate('totalAmount'), style: AppTextStyles.subtitle2),
                        Text(
                          '${payment.amount.toStringAsFixed(0)} ${l10n.currency}',
                          style: AppTextStyles.subtitle1.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
    
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (onDone != null) {
                      onDone!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(l10n.translate('doneBtn'), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.subtitle2),
        ],
      ),
    );
  }
}
