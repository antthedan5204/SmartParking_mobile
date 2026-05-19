import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/parking_lot.dart';

class ParkingCard extends StatelessWidget {
  final ParkingLot lot;
  final VoidCallback? onNavigate;
  final VoidCallback? onTap;
  final LatLng? userPosition;

  const ParkingCard({
    super.key,
    required this.lot,
    this.onNavigate,
    this.onTap,
    this.userPosition,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final available = lot.availableSlots ?? 0;
    final total = lot.totalSlots;

    // Pre-compute distance once per build, not inside the widget tree.
    final String? distanceText = (userPosition != null && lot.latitude != null && lot.longitude != null)
        ? LocationService.calculateDistance(userPosition!, LatLng(lot.latitude!, lot.longitude!)).toStringAsFixed(1)
        : null;
    final occupancyPercent = total > 0 ? (total - available) / total : 0.0;

    // Robust full status: only show "Full" if total > 0 and available <= 0
    // If total is 0, we treat it as unknown/loading (not full)
    final isFull = total > 0 && available <= 0;
    
    final backgroundColor = isFull ? AppColors.lotFull : AppColors.lotAvailable;
    final accentColor = isFull ? AppColors.danger : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lot.name,
                      style: AppTextStyles.heading3.copyWith(fontSize: 18),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFull ? AppColors.danger.withValues(alpha: 0.1) : Colors.white70,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isFull ? 'HẾT CHỖ' : 'CÒN CHỖ',
                      style: AppTextStyles.caption.copyWith(
                        color: isFull ? AppColors.danger : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                lot.address,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              if (distanceText != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.directions_walk, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Cách bạn $distanceText km',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              if (lot.hasEvStation == true) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.ev_station, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      l10n.evChargingSpots,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // Slots & Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sức chứa bãi đỗ', style: AppTextStyles.caption),
                      Text(
                        '$available / $total chỗ trống',
                        style: AppTextStyles.subtitle2.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Text(
                    '${(occupancyPercent * 100).toInt()}%',
                    style: AppTextStyles.subtitle1.copyWith(color: accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: occupancyPercent,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Footer: Price & Navigate
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Giá theo giờ', style: AppTextStyles.caption),
                        Text(
                          '${lot.pricePerHour.toStringAsFixed(0)} ${l10n.currency}',
                          style: AppTextStyles.subtitle1,
                        ),
                      ],
                    ),
                  ),
                  _buildCircleAction(
                    icon: Icons.navigation_rounded,
                    color: accentColor,
                    onTap: onNavigate ?? () {},
                  ),
                  const SizedBox(width: 8),
                  _buildCircleAction(
                    icon: Icons.arrow_forward_rounded,
                    color: Colors.black,
                    onTap: onTap ?? () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
