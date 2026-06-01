import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/map_utils.dart';
import '../../domain/entities/parking_lot.dart';
import '../providers/parking_provider.dart';
import '../pages/select_slot_page.dart';
import 'parking_lot_details_sheet.dart';

class ParkingMapView extends ConsumerStatefulWidget {
  const ParkingMapView({super.key});

  @override
  ConsumerState<ParkingMapView> createState() => _ParkingMapViewState();
}

class _ParkingMapViewState extends ConsumerState<ParkingMapView> {
  final MapController _mapController = MapController();

  // Default center (Ho Chi Minh City)
  static const _defaultCenter = LatLng(10.7769, 106.7009);

  LatLng? _userPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
      });
      // Ensure map is rendered before moving
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(_userPosition!, 14);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final parkingState = ref.watch(parkingLotsProvider);
    final l10n = AppLocalizations.of(context);
    final lots = parkingState.filteredLots;

    // Determine center from lots or use default
    final center = lots.isNotEmpty &&
            lots.first.latitude != null &&
            lots.first.longitude != null
        ? LatLng(lots.first.latitude!, lots.first.longitude!)
        : _defaultCenter;

    return Column(
      children: [
        // Legend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(AppColors.success, l10n.available),
              const SizedBox(width: 24),
              _legendItem(AppColors.danger, l10n.taken),
            ],
          ),
        ),

        // Map
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartparking.app',
                    keepBuffer: 3, // Keep more tiles in buffer to prevent blank areas when panning
                  ),
                  MarkerLayer(
                    markers: [
                      // User position marker
                      if (_userPosition != null)
                        Marker(
                          point: _userPosition!,
                          width: 40,
                          height: 40,
                          child: RepaintBoundary(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.my_location, color: Colors.blue, size: 20),
                              ),
                            ),
                          ),
                        ),
                      // Parking lot markers
                      ...lots
                          .where((lot) =>
                              lot.latitude != null && lot.longitude != null)
                          .map((lot) => _buildMarker(lot)),
                    ],
                  ),
                ],
              ),
              
              // FABs
              Positioned(
                bottom: 24,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'my_location',
                  onPressed: _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: AppColors.primary),
                ),
              ),

              // Loading overlay on top of the map
              if (parkingState.isLoading)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Text(l10n.loading, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Stats summary
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          margin: const EdgeInsets.only(bottom: 90),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                '${lots.fold<int>(0, (sum, lot) => sum + (lot.availableSlots ?? 0))}',
                l10n.availableSlots,
                AppColors.success,
              ),
              _statItem(
                '${lots.length}',
                l10n.zones,
                AppColors.info,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Marker _buildMarker(ParkingLot lot) {
    final hasAvailable = (lot.availableSlots ?? 0) > 0;
    final color = hasAvailable ? AppColors.success : AppColors.danger;

    return Marker(
      point: LatLng(lot.latitude!, lot.longitude!),
      width: 50,
      height: 50,
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: () => _showLotInfo(lot),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${lot.availableSlots ?? 0}',
                style: AppTextStyles.subtitle2.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLotInfo(ParkingLot lot) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ParkingLotDetailsSheet(
          lot: lot,
          onPay: () {
            Navigator.pop(ctx);
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => SelectSlotPage(lot: lot),
              ),
            );
          },
          onNavigate: () {
            Navigator.pop(ctx);
            MapUtils.openExternalMap(lot.latitude!, lot.longitude!);
          },
        );
      },
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(color: color),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
