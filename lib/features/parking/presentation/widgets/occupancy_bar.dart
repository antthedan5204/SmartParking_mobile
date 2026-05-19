import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class OccupancyBar extends StatelessWidget {
  final int available;
  final int total;

  const OccupancyBar({
    super.key,
    required this.available,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? available / total : 0.0;
    final color = ratio > 0.5
        ? AppColors.occupancyHigh
        : ratio > 0.2
            ? AppColors.occupancyMedium
            : AppColors.occupancyLow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Occupancy',
              style: AppTextStyles.caption,
            ),
            Text(
              '$available/$total',
              style: AppTextStyles.subtitle2.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? (total - available) / total : 0,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
