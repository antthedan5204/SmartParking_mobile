import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../parking/domain/entities/parking_lot.dart';
import '../../../parking/domain/entities/parking_slot.dart';
import '../../../parking/presentation/providers/parking_provider.dart';
import '../providers/manage_slots_provider.dart';
import '../../../admin/presentation/providers/booking_management_provider.dart';
import '../../../parking/domain/entities/booking.dart';
import '../../../parking/presentation/widgets/booking_success_sheet.dart';
import 'manager_booking_page.dart';

class ManageSlotsPage extends ConsumerStatefulWidget {
  final ParkingLot lot;

  const ManageSlotsPage({super.key, required this.lot});

  @override
  ConsumerState<ManageSlotsPage> createState() => _ManageSlotsPageState();
}

class _ManageSlotsPageState extends ConsumerState<ManageSlotsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingManagementProvider.notifier).loadBookings();
    });
  }
  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(parkingSlotsProvider(widget.lot.id));
    final manageState = ref.watch(manageSlotsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.translate('manageSlots'), style: AppTextStyles.subtitle1),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(parkingSlotsProvider(widget.lot.id)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Lot info header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.lot.name,
                        style: AppTextStyles.subtitle2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(l10n.translate('availableSlot'), Colors.white, AppColors.primary),
                    _buildLegendItem(l10n.translate('maintenanceSlot'), Colors.amber.withValues(alpha: 0.15), Colors.amber, isMaintenance: true),
                    _buildLegendItem(l10n.translate('occupiedSlot'), Colors.transparent, Colors.transparent, isCar: true),
                    if (widget.lot.hasEvStation == true)
                      _buildLegendItem(l10n.translate('evStation'), Colors.white, AppColors.success, isEV: true),
                  ],
                ),
              ),

              // Slots Grid
              Expanded(
                child: slotsAsync.when(
                  data: (slots) {
                    if (slots.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(l10n.translate('noSlotsAvailable'), style: AppTextStyles.subtitle2),
                          ],
                        ),
                      );
                    }
                    
                    final sortedSlots = List<ParkingSlot>.from(slots)
                      ..sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
                    
                    return _buildGrid(sortedSlots);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        l10n.translate('dataLoadError').replaceAll('{error}', err.toString()),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          if (manageState is AsyncLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bg, Color border, {bool isCar = false, bool isMaintenance = false, bool isEV = false}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 24,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border.withValues(alpha: 0.5), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: isCar 
                ? Icon(Icons.directions_car_filled_rounded, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.7))
                : isMaintenance
                    ? const Icon(Icons.build_rounded, size: 12, color: Colors.amber)
                    : isEV
                        ? const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.success)
                        : Container(
                            width: 16,
                            height: 10,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1),
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.transparent,
                            ),
                          ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGrid(List<ParkingSlot> slots) {
    if (slots.isEmpty) return const SizedBox();

    const int rowsPerColumn = 10;
    const int slotsPerBlock = rowsPerColumn * 2;
    const double slotWidth = 135.0;
    const double slotHeight = 65.0;
    const double aisleWidth = 60.0;

    final int numBlocks = (slots.length / slotsPerBlock).ceil();

    return Container(
      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(numBlocks, (blockIndex) {
              final start = blockIndex * slotsPerBlock;
              final end = (start + slotsPerBlock < slots.length) ? start + slotsPerBlock : slots.length;
              final blockSlots = slots.sublist(start, end);

              return Row(
                children: [
                  _buildParkingBlock(blockSlots, rowsPerColumn, slotWidth, slotHeight),
                  if (blockIndex < numBlocks - 1) _buildAisle(aisleWidth, rowsPerColumn * slotHeight),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildParkingBlock(List<ParkingSlot> blockSlots, int rows, double width, double height) {
    return SizedBox(
      width: (blockSlots.length > rows ? 2 : 1) * width,
      height: rows * height,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: rows,
          childAspectRatio: height / width,
        ),
        itemCount: blockSlots.length,
        itemBuilder: (context, index) {
          final slot = blockSlots[index];
          final isOccupied = slot.status.toLowerCase() == 'occupied';
          final isMaintenance = slot.status.toLowerCase() == 'maintenance';

          final isFirstCol = index < rows;
          final isFirstRow = index % rows == 0;

          Color borderColor = AppColors.primary.withValues(alpha: 0.35);
          Color bgColor = Colors.white;
          Widget? centerWidget;

          if (isOccupied) {
            borderColor = AppColors.textSecondary.withValues(alpha: 0.3);
            centerWidget = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: RotatedBox(
                quarterTurns: 1,
                child: Image.asset('assets/images/car_top.png', fit: BoxFit.contain),
              ),
            );
          } else if (isMaintenance) {
            borderColor = Colors.amber;
            bgColor = Colors.amber.withValues(alpha: 0.08);
            centerWidget = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 1.5),
                borderRadius: BorderRadius.circular(6),
                color: Colors.amber.withValues(alpha: 0.15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.build_rounded, size: 12, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    slot.slotNumber,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Available
            if (slot.isEvCharging) {
              borderColor = AppColors.success;
              bgColor = AppColors.success.withValues(alpha: 0.03);
            }
            centerWidget = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: slot.isEvCharging ? AppColors.success : AppColors.primary.withValues(alpha: 0.35),
                  width: slot.isEvCharging ? 2.0 : 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
                color: slot.isEvCharging ? AppColors.success.withValues(alpha: 0.05) : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (slot.isEvCharging)
                    const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.success),
                  Text(
                    slot.slotNumber,
                    style: AppTextStyles.caption.copyWith(
                      color: slot.isEvCharging ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return GestureDetector(
            onTap: () => _showSlotDetailsBottomSheet(context, slot, AppLocalizations.of(context)),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  left: isFirstCol ? BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5) : BorderSide.none,
                  top: isFirstRow ? BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5) : BorderSide.none,
                  right: BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
                  bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
                ),
              ),
              child: Center(child: centerWidget),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAisle(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 2,
            height: height,
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) => Icon(
              index % 2 == 0 ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
              color: AppColors.primary.withValues(alpha: 0.1),
              size: 24,
            )),
          ),
        ],
      ),
    );
  }

  void _showSlotDetailsBottomSheet(BuildContext context, ParkingSlot slot, AppLocalizations l10n) {
    final isOccupied = slot.status.toLowerCase() == 'occupied';
    final isMaintenance = slot.status.toLowerCase() == 'maintenance';
    
    // Find active booking for occupied slot
    Booking? activeBooking;
    if (isOccupied) {
      final bookingState = ref.read(bookingManagementProvider);
      for (final b in bookingState.bookings) {
        if (b.slotId == slot.id && (b.status == BookingStatus.checkedIn || b.status == BookingStatus.confirmed)) {
          activeBooking = b;
          break;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Slot Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            slot.slotNumber,
                            style: AppTextStyles.subtitle1.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOccupied 
                                ? Colors.red.withValues(alpha: 0.1)
                                : isMaintenance
                                    ? Colors.amber.withValues(alpha: 0.1)
                                    : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOccupied
                                ? l10n.translate('statusOccupied')
                                : isMaintenance
                                    ? l10n.translate('statusMaintenance')
                                    : l10n.translate('statusAvailable'),
                            style: AppTextStyles.caption.copyWith(
                              color: isOccupied 
                                  ? Colors.red
                                  : isMaintenance
                                      ? Colors.amber.shade800
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Attributes List
                _buildInfoRow(
                  icon: Icons.flash_on_rounded, 
                  label: l10n.translate('evStationLabel'), 
                  value: slot.isEvCharging ? l10n.translate('integrated') : l10n.translate('none'),
                  valueColor: slot.isEvCharging ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.info_outline_rounded, 
                  label: l10n.translate('slotIdLabel'), 
                  value: '#${slot.id}',
                ),
                
                // Show booking info if occupied
                if (isOccupied && activeBooking != null) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.credit_card_rounded, 
                    label: l10n.translate('licensePlateLabel'), 
                    value: activeBooking.vehiclePlateNumber ?? l10n.translate('unknown'),
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.history_rounded, 
                    label: l10n.translate('bookingIdLabel'), 
                    value: '#${activeBooking.id}',
                  ),
                ],
                const SizedBox(height: 24),

                // Description message
                Text(
                  isOccupied
                      ? l10n.translate('occupiedSlotDesc')
                      : isMaintenance
                          ? l10n.translate('maintenanceSlotDesc')
                          : l10n.translate('availableSlotDesc'),
                  style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                // Action Button
                if (isMaintenance)
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await ref
                          .read(manageSlotsProvider.notifier)
                          .updateSlotStatus(slot.id, 'Available', slot.lotId);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success 
                                ? l10n.translate('unlockSlotSuccess').replaceAll('{slotNumber}', slot.slotNumber) 
                                : l10n.translate('updateStatusFailed')),
                            backgroundColor: success ? AppColors.success : AppColors.danger,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                    label: Text(l10n.translate('unlockSlotBtn')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  )
                else if (isOccupied) ...[
                  if (activeBooking != null)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.translate('confirmCheckoutTitle')),
                            content: Text(l10n.translate('confirmCheckoutSub').replaceAll('{slotNumber}', slot.slotNumber).replaceAll('{plate}', activeBooking?.vehiclePlateNumber ?? "")),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.translate('cancel')),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                                child: Text(l10n.translate('confirm')),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          Navigator.pop(context); // Close bottom sheet
                          final success = await ref
                              .read(manageSlotsProvider.notifier)
                              .checkoutVehicle(activeBooking!.id, slot.lotId, slot.id);
                          
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.translate('checkoutSuccess')),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            ref.read(bookingManagementProvider.notifier).loadBookings();
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.translate('checkoutFailed')),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      label: Text(l10n.translate('checkoutForGuestBtn')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.translate('freeSlotTitle')),
                            content: Text(l10n.translate('freeSlotSub').replaceAll('{slotNumber}', slot.slotNumber)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.translate('cancel')),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                child: Text(l10n.translate('confirm')),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          Navigator.pop(context);
                          final success = await ref
                              .read(manageSlotsProvider.notifier)
                              .updateSlotStatus(slot.id, 'Available', slot.lotId);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success 
                                    ? l10n.translate('freeSlotSuccess').replaceAll('{slotNumber}', slot.slotNumber) 
                                    : l10n.translate('updateStatusFailed')),
                                backgroundColor: success ? AppColors.success : AppColors.danger,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      label: Text(l10n.translate('manualFreeSlotBtn')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  
                  if (activeBooking != null) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.translate('freeSlotTitle')),
                            content: Text(l10n.translate('freeSlotSub').replaceAll('{slotNumber}', slot.slotNumber)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.translate('cancel')),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                child: Text(l10n.translate('confirm')),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          Navigator.pop(context);
                          final success = await ref
                              .read(manageSlotsProvider.notifier)
                              .updateSlotStatus(slot.id, 'Available', slot.lotId);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success 
                                    ? l10n.translate('freeSlotSuccess').replaceAll('{slotNumber}', slot.slotNumber) 
                                    : l10n.translate('updateStatusFailed')),
                                backgroundColor: success ? AppColors.success : AppColors.danger,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(l10n.translate('manualFreeSlotDesc')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet first
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ManagerBookingPage(
                            lot: widget.lot,
                            slot: slot,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_ind_rounded, color: Colors.white),
                    label: Text(l10n.translate('bookForGuestBtn')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await ref
                          .read(manageSlotsProvider.notifier)
                          .updateSlotStatus(slot.id, 'Maintenance', slot.lotId);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success 
                                ? l10n.translate('setMaintenanceSuccess').replaceAll('{slotNumber}', slot.slotNumber) 
                                : l10n.translate('updateStatusFailed')),
                            backgroundColor: success ? AppColors.success : AppColors.danger,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.build_rounded, color: Colors.white),
                    label: Text(l10n.translate('setMaintenanceBtn')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon, 
    required String label, 
    required String value, 
    Color valueColor = AppColors.textPrimary
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Text(
          value, 
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
