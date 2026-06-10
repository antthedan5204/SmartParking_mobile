import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/parking_provider.dart';
import 'parking_card.dart';
import 'parking_lot_details_sheet.dart';
import '../pages/select_slot_page.dart';
import '../../../../core/utils/map_utils.dart';

class ParkingListView extends ConsumerStatefulWidget {
  const ParkingListView({super.key});

  @override
  ConsumerState<ParkingListView> createState() => _ParkingListViewState();
}

class _ParkingListViewState extends ConsumerState<ParkingListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(parkingLotsProvider).lots.isEmpty) {
        ref.read(parkingLotsProvider.notifier).loadParkingLots();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final parkingState = ref.watch(parkingLotsProvider);
    final userPosition = ref.watch(userLocationProvider);
    final l10n = AppLocalizations.of(context);

    if (parkingState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (parkingState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(parkingState.errorMessage!, style: AppTextStyles.body2),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(parkingLotsProvider.notifier).loadParkingLots(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final lots = parkingState.filteredLots;

    if (lots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_parking_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(l10n.noData, style: AppTextStyles.body2),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(parkingLotsProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: lots.length,
        itemBuilder: (context, index) {
          final lot = lots[index];
          return ParkingCard(
            lot: lot,
            userPosition: userPosition,
            onTap: () => _showDetails(context, lot),
            onNavigate: () {
              if (lot.latitude != null && lot.longitude != null) {
                MapUtils.openExternalMap(lot.latitude!, lot.longitude!);
              }
            },
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, dynamic lot) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ParkingLotDetailsSheet(
        lot: lot,
        onNavigate: () {
          Navigator.pop(context);
          if (lot.latitude != null && lot.longitude != null) {
            MapUtils.openExternalMap(lot.latitude!, lot.longitude!);
          }
        },
        onPay: () {
          Navigator.pop(context);
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (context) => SelectSlotPage(lot: lot)),
          );
        },
      ),
    );
  }
}
