import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/parking_map_view.dart';

/// Wrapper page for the Map tab in the bottom navigation bar.
/// Adds a styled header on top of the existing [ParkingMapView] widget.
class MapTabPage extends StatelessWidget {
  const MapTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.map_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bản đồ', style: AppTextStyles.heading3),
                        Text('Tìm bãi đỗ xe quanh bạn',
                            style: AppTextStyles.body2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Map content
            const Expanded(child: ParkingMapView()),
          ],
        ),
      ),
    );
  }
}
