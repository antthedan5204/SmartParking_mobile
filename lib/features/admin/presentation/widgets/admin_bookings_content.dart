import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../parking/domain/entities/booking.dart';
import '../providers/booking_management_provider.dart';

class AdminBookingsContent extends ConsumerWidget {
  final bool isHistoryView;

  const AdminBookingsContent({super.key, this.isHistoryView = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(bookingManagementProvider);
    final now = DateTime.now();
    
    // Filter bookings based on view mode (History vs Active)
    final bookings = state.filteredBookings.where((b) {
      final isEnded = now.isAfter(b.endTime);
      final isFinished = b.status == BookingStatus.completed || b.status == BookingStatus.cancelled;
      
      if (isHistoryView) {
        return isFinished || (isEnded && b.status != BookingStatus.checkedIn);
      } else {
        return !isFinished && (!isEnded || b.status == BookingStatus.checkedIn);
      }
    }).toList();

    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            children: [
              Row(
                children: [
                  // Lot Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: state.selectedLotName,
                      decoration: InputDecoration(
                        labelText: l10n.translate('parkingLot'),
                        prefixIcon: const Icon(Icons.business),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.translate('allLots'))),
                        ...state.availableLotNames.map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => ref.read(bookingManagementProvider.notifier).setLotFilter(val),
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Filter
                  Expanded(
                    child: DropdownButtonFormField<BookingStatus>(
                      value: state.selectedStatus,
                      decoration: InputDecoration(
                        labelText: l10n.translate('statusLabel'),
                        prefixIcon: const Icon(Icons.info_outline),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.translate('all'))),
                        DropdownMenuItem(value: BookingStatus.confirmed, child: Text(l10n.confirmed)),
                        DropdownMenuItem(value: BookingStatus.checkedIn, child: Text(l10n.translate('statusCheckedIn'))),
                        DropdownMenuItem(value: BookingStatus.completed, child: Text(l10n.completed)),
                        DropdownMenuItem(value: BookingStatus.cancelled, child: Text(l10n.cancelled)),
                      ],
                      onChanged: (val) => ref.read(bookingManagementProvider.notifier).setStatusFilter(val),
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search Bar & Date Picker
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l10n.translate('searchGuestOrPlate'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) => ref.read(bookingManagementProvider.notifier).setSearchQuery(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: state.startDate != null && state.endDate != null
                            ? DateTimeRange(start: state.startDate!, end: state.endDate!)
                            : null,
                      );
                      if (picked != null) {
                        ref.read(bookingManagementProvider.notifier).setDateRange(picked.start, picked.end);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 20),
                    tooltip: l10n.translate('filterByDate'),
                  ),
                ],
              ),
              if (state.startDate != null || state.endDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        '${l10n.translate('fromPrefix')}${state.startDate != null ? DateFormat('dd/MM/yyyy').format(state.startDate!) : '...'} - '
                        '${l10n.translate('toPrefix')}${state.endDate != null ? DateFormat('dd/MM/yyyy').format(state.endDate!) : '...'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () => ref.read(bookingManagementProvider.notifier).setDateRange(null, null),
                      deleteIconColor: AppColors.danger,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Booking List
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : bookings.isEmpty
                  ? Center(child: Text(l10n.noData))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(bookingManagementProvider.notifier).loadBookings(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          return _buildBookingCard(context, ref, bookings[index], l10n);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, WidgetRef ref, Booking booking, AppLocalizations l10n) {
    final dateFormat = DateFormat('dd/MM HH:mm');
    final statusColor = _getStatusColor(booking.status);
    final now = DateTime.now();
    final isExpired = now.isAfter(booking.endTime);
    final isConfirmed = booking.status == BookingStatus.confirmed;
    final isCheckedIn = booking.status == BookingStatus.checkedIn;
    final isOvertime = isCheckedIn && isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Status
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.book_online_outlined, color: statusColor),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ID: #${booking.id}',
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              if (isExpired && !isCheckedIn && booking.status == BookingStatus.confirmed)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(l10n.translate('overdue'), style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              if (isOvertime)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(l10n.translate('parkingOvertime'), style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              _StatusBadge(status: booking.status, l10n: l10n),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(booking.lotName ?? l10n.translate('unknown'), style: AppTextStyles.subtitle1),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${l10n.translate('guestPrefix')}${booking.userId}', style: AppTextStyles.caption),
                          const SizedBox(width: 12),
                          const Icon(Icons.directions_car_filled_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${l10n.translate('vehiclePrefix')}${booking.vehicleId}', style: AppTextStyles.caption),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${dateFormat.format(booking.startTime)} - ${dateFormat.format(booking.endTime)}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('totalAmountPrefix'),
                  style: AppTextStyles.caption,
                ),
                Text(
                  '${NumberFormat.decimalPattern().format(booking.totalPrice)}${l10n.translate('currencyShort')}',
                  style: AppTextStyles.subtitle2.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (isOvertime || isHistoryView) ...[
            Builder(
              builder: (context) {
                double penaltyFee = 0;
                
                if (isOvertime) {
                  final overtimeMinutes = now.difference(booking.endTime).inMinutes;
                  penaltyFee = overtimeMinutes > 10 ? (overtimeMinutes * 1000).toDouble() : 0;
                } else if (isHistoryView) {
                  if (booking.penaltyFee > 0) {
                    penaltyFee = booking.penaltyFee;
                  } else if (booking.actualCheckoutTime != null) {
                    final overtimeMinutes = booking.actualCheckoutTime!.difference(booking.endTime).inMinutes;
                    penaltyFee = overtimeMinutes > 10 ? (overtimeMinutes * 1000).toDouble() : 0;
                  }
                }

                if (penaltyFee > 0) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppColors.danger.withValues(alpha: 0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHistoryView ? l10n.translate('collectedPenaltyFee') : l10n.translate('penaltyFee'),
                          style: AppTextStyles.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${NumberFormat.decimalPattern().format(penaltyFee)} ${l10n.translate('currencyShort')}',
                          style: AppTextStyles.subtitle2.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
            ),
          ],
          if (!isHistoryView && (isConfirmed || isCheckedIn) && !isExpired) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Check-in button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (isConfirmed)
                          ? () => _handleCheckIn(context, ref, booking, l10n)
                          : null,
                      icon: const Icon(Icons.login, size: 16),
                      label: Text(l10n.translate('checkInBtn')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Check-out button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (isCheckedIn)
                          ? () => _handleCheckOut(context, ref, booking, l10n)
                          : null,
                      icon: const Icon(Icons.logout, size: 16),
                      label: Text(l10n.translate('checkOutBtn')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Special case: Allow check-out even if expired if they are currently checked in
          if (!isHistoryView && isCheckedIn && isExpired) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleCheckOut(context, ref, booking, l10n),
                  icon: const Icon(Icons.logout, size: 16),
                  label: Text(l10n.translate('checkOutOvertimeBtn')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleCheckIn(BuildContext context, WidgetRef ref, Booking booking, AppLocalizations l10n) async {
    final success = await ref.read(bookingManagementProvider.notifier).checkInBooking(booking.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('checkInSuccess'))),
      );
    }
  }

  void _handleCheckOut(BuildContext context, WidgetRef ref, Booking booking, AppLocalizations l10n) async {
    final success = await ref.read(bookingManagementProvider.notifier).completeBooking(booking.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('checkOutSuccess'))),
      );
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return AppColors.warning;
      case BookingStatus.confirmed: return AppColors.info;
      case BookingStatus.checkedIn: return Colors.blue;
      case BookingStatus.completed: return AppColors.success;
      case BookingStatus.cancelled: return AppColors.danger;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  final AppLocalizations l10n;

  const _StatusBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    switch (status) {
      case BookingStatus.pending:
        text = l10n.translate('statusPending');
        color = AppColors.warning;
        break;
      case BookingStatus.confirmed:
        text = l10n.confirmed;
        color = AppColors.info;
        break;
      case BookingStatus.checkedIn:
        text = l10n.translate('statusCheckedIn');
        color = Colors.blue;
        break;
      case BookingStatus.completed:
        text = l10n.completed;
        color = AppColors.success;
        break;
      case BookingStatus.cancelled:
        text = l10n.cancelled;
        color = AppColors.danger;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
