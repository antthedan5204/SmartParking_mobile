import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/map_utils.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/parking_lot.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/parking_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/extend_booking_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BookingDetailsPage extends ConsumerWidget {
  final Booking booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Check role
    final authState = ref.watch(authProvider);
    final isManagerOrAdmin =
        authState.user?.isManager == true || authState.user?.isAdmin == true;

    // Get parking lot details
    final parkingState = ref.read(parkingLotsProvider);
    ParkingLot lot;
    try {
      lot = parkingState.lots.firstWhere((l) => l.name == booking.lotName);
    } catch (_) {
      lot = parkingState.lots.isNotEmpty
          ? parkingState.lots.first
          : ParkingLot(
              id: 0,
              name: l10n.translate('unknown'),
              address: l10n.translate('unknownAddress'),
              totalSlots: 0,
              pricePerHour: 0,
            );
    }

    final now = DateTime.now();
    final isConfirmed = booking.status == BookingStatus.confirmed;
    final isCheckedIn = booking.status == BookingStatus.checkedIn;
    final isNearStart =
        isConfirmed &&
        booking.startTime.difference(now).inMinutes <= 30 &&
        booking.startTime.isAfter(now);
    final canCancel =
        isConfirmed && booking.startTime.difference(now).inMinutes > 30;
    final canExtend = isCheckedIn && booking.endTime.isAfter(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Very light gray background
      appBar: AppBar(
        title: Text(
          l10n.translate('viewBookingDetails'),
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD), // Light blue background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFBBDEFB),
                ), // Slightly darker blue border
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFBBDEFB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF1976D2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.translate('bookingIdLabel')} #${booking.id}',
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(booking.status, l10n),
                        style: TextStyle(
                          color: _getStatusColor(booking.status),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Chi tiết bãi đỗ
            _buildSectionHeader(
              Icons.location_on,
              l10n.translate('parkingDetailsSection'),
            ),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.lotName ?? l10n.translate('unknown'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lot.address.toLowerCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isManagerOrAdmin) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (lot.latitude != null && lot.longitude != null) {
                            MapUtils.openExternalMap(
                              lot.latitude!,
                              lot.longitude!,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.translate('noCoordinatesFound'),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.turn_right_rounded,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          l10n.translate('directions'),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (isManagerOrAdmin) ...[
              const SizedBox(height: 24),
              // Section 2: Thông tin khách hàng
              _buildSectionHeader(
                Icons.person_rounded,
                l10n.translate('customerInfo'),
              ),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  children: [
                    _buildInfoRow(
                      l10n.translate('customerId'),
                      '#${booking.userId}',
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Section 3: Thông tin gửi xe
            _buildSectionHeader(
              Icons.local_parking_rounded,
              l10n.translate('parkingInfoTitle'),
            ),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  _buildInfoRow(
                    l10n.translate('licensePlateLabel'),
                    booking.vehiclePlateNumber ?? '',
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFF0F0F0),
                  ),
                  _buildInfoRow(
                    l10n.translate('slotLabel'),
                    '${l10n.translate('slotPrefix') ?? 'Ô số '}${booking.slotNumber ?? ''}',
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFF0F0F0),
                  ),
                  _buildInfoRow(
                    l10n.translate('timeIn'),
                    DateFormat(
                      'HH:mm, dd/MM/yyyy',
                    ).format(booking.startTime.toLocal()),
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFF0F0F0),
                  ),
                  _buildInfoRow(
                    l10n.translate('timeOut'),
                    DateFormat(
                      'HH:mm, dd/MM/yyyy',
                    ).format(booking.endTime.toLocal()),
                  ),
                  if (booking.actualCheckoutTime != null) ...[
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                    ),
                    _buildInfoRow(
                      l10n.translate('actualCheckout'),
                      DateFormat(
                        'HH:mm, dd/MM/yyyy',
                      ).format(booking.actualCheckoutTime!.toLocal()),
                    ),
                  ],
                  if (booking.extensionTime != null &&
                      booking.extensionTime! > 0) ...[
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                    ),
                    _buildInfoRow(
                      l10n.translate('extendedTime'),
                      l10n
                          .translate('addedMinutes')
                          .replaceAll(
                            '{min}',
                            booking.extensionTime.toString(),
                          ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Chi tiết thanh toán
            _buildSectionHeader(
              Icons.credit_card_rounded,
              l10n.translate('paymentDetailsTitle'),
            ),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('parkingFeeLabel'),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${NumberFormat.decimalPattern().format(booking.totalPrice)} ${l10n.translate('currencyShort')}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      double displayPenaltyFee = booking.penaltyFee;
                      if (displayPenaltyFee == 0 && booking.status == BookingStatus.checkedIn) {
                        final localEnd = booking.endTime.toLocal();
                        final overtimeMinutes = DateTime.now().difference(localEnd).inMinutes;
                        if (overtimeMinutes > 10) {
                          displayPenaltyFee = (overtimeMinutes * 1000).toDouble();
                        }
                      }
                      
                      if (displayPenaltyFee > 0) {
                        return Column(
                          children: [
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.translate('penaltyFee'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${NumberFormat.decimalPattern().format(displayPenaltyFee)} ${l10n.translate('currencyShort')}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  if (booking.extensionFee > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.translate('extensionFee'),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${NumberFormat.decimalPattern().format(booking.extensionFee)} ${l10n.translate('currencyShort')}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Builder(
                    builder: (context) {
                      double displayPenaltyFee = booking.penaltyFee;
                      if (displayPenaltyFee == 0 && booking.status == BookingStatus.checkedIn) {
                        final localEnd = booking.endTime.toLocal();
                        final overtimeMinutes = DateTime.now().difference(localEnd).inMinutes;
                        if (overtimeMinutes > 10) {
                          displayPenaltyFee = (overtimeMinutes * 1000).toDouble();
                        }
                      }
                      
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.translate('totalAmount'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${NumberFormat.decimalPattern().format(booking.totalPrice + displayPenaltyFee + booking.extensionFee)} ${l10n.translate('currencyShort')}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          (!isManagerOrAdmin && (isConfirmed || canExtend || canCancel))
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canCancel || canExtend)
                      Row(
                        children: [
                          if (canCancel)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _handleCancel(context, ref, booking, l10n),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: Text(l10n.translate('cancelBooking')),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(
                                    color: AppColors.danger,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                          if (canCancel && canExtend) const SizedBox(width: 12),

                          if (canExtend)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ExtendBookingDialog(booking: booking),
                                  );
                                },
                                icon: const Icon(Icons.more_time_rounded),
                                label: Text(l10n.translate('extendBooking')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                        ],
                      ),

                    if (isConfirmed) ...[
                      if (canCancel || canExtend) const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showQRCode(context, booking, l10n),
                          icon: const Icon(Icons.qr_code_rounded, size: 18),
                          label: Text(l10n.translate('viewQRForCheckIn')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : null,
    );
  }

  void _handleCancel(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('cancelConfirmTitle')),
        content: Text(l10n.translate('cancelConfirmSub')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('noBtn')),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context); // Close dialog
              final success = await ref
                  .read(bookingProvider.notifier)
                  .cancelBooking(booking.id);
              if (success && context.mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.translate('cancelSuccess'))),
                );
                context.pop(); // Go back from details page
              }
            },
            child: Text(
              l10n.translate('cancelBookingBtn'),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCode(
    BuildContext context,
    Booking booking,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('qrCodeTitle'), textAlign: TextAlign.center),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: 'BOOKING:${booking.id}',
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text('#${booking.id}', style: AppTextStyles.subtitle2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return AppColors.primary;
      case BookingStatus.checkedIn:
        return const Color(0xFF1976D2); // Match the exact blue in the image
      case BookingStatus.completed:
        return AppColors.textSecondary;
      case BookingStatus.cancelled:
        return AppColors.danger;
    }
    return AppColors.textPrimary;
  }

  String _getStatusText(BookingStatus status, AppLocalizations l10n) {
    switch (status) {
      case BookingStatus.pending:
        return l10n.translate('statusPending');
      case BookingStatus.confirmed:
        return l10n.translate('confirmed');
      case BookingStatus.checkedIn:
        return l10n.translate('statusCheckedIn');
      case BookingStatus.completed:
        return l10n.translate('statusCompleted');
      case BookingStatus.cancelled:
        return l10n.translate('statusCancelled');
    }
    return '';
  }
}
