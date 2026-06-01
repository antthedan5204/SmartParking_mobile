import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/parking_lot.dart';
import '../../domain/entities/parking_slot.dart';
import '../providers/parking_provider.dart';
import 'virtual_payment_page.dart';

class SelectSlotPage extends ConsumerStatefulWidget {
  final ParkingLot lot;
  final DateTime? startTime;
  final DateTime? endTime;

  const SelectSlotPage({super.key, required this.lot, this.startTime, this.endTime});

  @override
  ConsumerState<SelectSlotPage> createState() => _SelectSlotPageState();
}

class _SelectSlotPageState extends ConsumerState<SelectSlotPage> {
  final ValueNotifier<ParkingSlot?> _selectedSlotNotifier = ValueNotifier(null);

  @override
  void dispose() {
    _selectedSlotNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(parkingSlotsProvider(widget.lot.id));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.translate('selectSlot'), style: AppTextStyles.subtitle1),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
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
                _buildLegendItem(l10n.translate('maintenanceSlot'), Colors.grey.shade100, Colors.grey.shade300, isMaintenance: true),
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
                
                // Sort slots by slot number to keep them in consistent positions
                // and avoid pushing booked ones to the bottom.
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

          // Bottom Action
          _buildBottomAction(context, l10n),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bg, Color border, {bool isCar = false, bool isSelected = false, bool isEV = false, bool isMaintenance = false}) {
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
                  ? const Icon(Icons.build_rounded, size: 12, color: Colors.grey)
                  : isEV
                      ? const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.success)
                      : Container(
                          width: 16,
                          height: 10,
                          decoration: BoxDecoration(
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4), width: 1),
                            borderRadius: BorderRadius.circular(2),
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                        ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGrid(List<dynamic> slots) {
    if (slots.isEmpty) return const SizedBox();

    const int rowsPerColumn = 10;
    const int slotsPerBlock = rowsPerColumn * 2; // 2 columns of 10
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

  Widget _buildParkingBlock(List<dynamic> blockSlots, int rows, double width, double height) {
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
          final slot = blockSlots[index] as ParkingSlot;
          final isOccupied = slot.status.toLowerCase() == 'occupied';
          final isMaintenance = slot.status.toLowerCase() == 'maintenance';

          final isFirstCol = index < rows;
          final isFirstRow = index % rows == 0;

          return ValueListenableBuilder<ParkingSlot?>(
            valueListenable: _selectedSlotNotifier,
            builder: (context, selectedSlot, child) {
              final isSelected = selectedSlot?.id == slot.id;

              return GestureDetector(
                onTap: (isOccupied || isMaintenance) ? null : () => _selectedSlotNotifier.value = slot,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.white,
                    border: Border(
                      left: isFirstCol ? BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5) : BorderSide.none,
                      top: isFirstRow ? BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5) : BorderSide.none,
                      right: BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
                      bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isOccupied)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: RotatedBox(
                            quarterTurns: 1, // Make car horizontal
                            child: Image.asset('assets/images/car_top.png', fit: BoxFit.contain),
                          ),
                        )
                      else if (isMaintenance)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.grey.shade100,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.build_rounded, 
                                size: 14, 
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                slot.slotNumber,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected 
                                  ? AppColors.primary 
                                  : (slot.isEvCharging ? AppColors.success : AppColors.primary.withValues(alpha: 0.35)),
                              width: slot.isEvCharging ? 2.0 : 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: isSelected 
                                ? AppColors.primary 
                                : (slot.isEvCharging ? AppColors.success.withValues(alpha: 0.05) : Colors.transparent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (slot.isEvCharging)
                                Icon(
                                  Icons.flash_on_rounded, 
                                  size: 16, 
                                  color: isSelected ? Colors.white : AppColors.success,
                                ),
                              Text(
                                slot.slotNumber,
                                style: AppTextStyles.caption.copyWith(
                                  color: isSelected 
                                      ? Colors.white 
                                      : (slot.isEvCharging ? AppColors.success : AppColors.primary),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
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
          // Middle divider line for the aisle
          Container(
            width: 2,
            height: height,
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
          // Directional arrows
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

  Widget _buildBottomAction(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ValueListenableBuilder<ParkingSlot?>(
          valueListenable: _selectedSlotNotifier,
          builder: (context, selectedSlot, child) {
            return ElevatedButton(
              onPressed: selectedSlot == null 
                  ? null 
                  : () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => VirtualPaymentPage(
                            lot: widget.lot,
                            amount: widget.lot.pricePerHour,
                            selectedSlotId: selectedSlot.id,
                            selectedSlotNumber: selectedSlot.slotNumber,
                            startTime: widget.startTime,
                            endTime: widget.endTime,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(l10n.translate('continueToPayment'), style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }
        ),
      ),
    );
  }
}
