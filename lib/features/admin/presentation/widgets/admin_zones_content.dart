import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../parking/presentation/providers/parking_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/user_management_provider.dart';
import 'add_zone_dialog.dart';
import '../pages/manage_slots_page.dart';

class AdminZonesContent extends ConsumerStatefulWidget {
  const AdminZonesContent({super.key});

  @override
  ConsumerState<AdminZonesContent> createState() => _AdminZonesContentState();
}

class _AdminZonesContentState extends ConsumerState<AdminZonesContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always refresh lots when entering the zones tab
      ref.read(parkingLotsProvider.notifier).loadParkingLots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parkingState = ref.watch(parkingLotsProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    // Backend already filters lots by role:
    // - Admin: returns all lots
    // - Manager: returns only their assigned lots
    final lots = parkingState.lots;

    return Column(
      children: [
        // Tab Header/Action
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAdmin ? l10n.zones : l10n.translate('myFacilities'),
                style: AppTextStyles.heading3,
              ),
              if (isAdmin)
                ElevatedButton.icon(
                  onPressed: () => _showAddZoneDialog(context, ref),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: Text(l10n.translate('addFacility')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ),

        // List of Zones
        Expanded(
          child: parkingState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : lots.isEmpty
                  ? Center(child: Text(l10n.noData))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lots.length,
                      itemBuilder: (context, index) {
                        final lot = lots[index];
                        return _buildZoneItem(context, ref, lot, l10n);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildZoneItem(BuildContext context, WidgetRef ref, dynamic lot, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ManageSlotsPage(lot: lot),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_parking, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lot.name, style: AppTextStyles.subtitle1),
                  Text(
                    lot.address,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.sensor_door_outlined, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        '${lot.availableSlots ?? 0}/${lot.totalSlots} ${l10n.translate('emptySlots')}',
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.translate('pricePerHourFormat').replaceAll('{price}', lot.pricePerHour.toStringAsFixed(0)),
                  style: AppTextStyles.subtitle2.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showAddZoneDialog(context, ref, lot: lot),
                      icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _deleteZone(context, ref, lot),
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddZoneDialog(BuildContext context, WidgetRef ref, {dynamic lot}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddZoneDialog(lot: lot),
    );

    if (result == true) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lot != null ? l10n.translate('updateSuccess') : l10n.translate('createFacilitySuccess')),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(parkingLotsProvider.notifier).loadParkingLots();
      }
    }
  }

  void _deleteZone(BuildContext context, WidgetRef ref, dynamic lot) async {
    final l10n = AppLocalizations.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirmDelete')),
        content: Text(l10n.translate('confirmDeleteLot').replaceAll('{lotName}', lot.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(userManagementProvider.notifier).deleteParkingLot(lot.id);
      
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('lotDeleted')),
              backgroundColor: AppColors.success,
            ),
          );
          ref.read(parkingLotsProvider.notifier).loadParkingLots();
        } else {
          final error = ref.read(userManagementProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? l10n.translate('deleteLotError')),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}
