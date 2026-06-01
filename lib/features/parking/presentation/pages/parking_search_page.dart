import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/parking_provider.dart';
import '../widgets/parking_list_view.dart';
import '../widgets/parking_map_view.dart';

/// Tab "Đặt chỗ" — gồm 2 sub-tab: Danh sách và Bản đồ
class ParkingSearchPage extends ConsumerWidget {
  const ParkingSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tabIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_parking_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.translate('booking'), style: AppTextStyles.heading3),
                          Text(l10n.translate('searchAndBookParking'),
                              style: AppTextStyles.body2
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  TextField(
                    onChanged: (val) =>
                        ref.read(parkingLotsProvider.notifier).setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: l10n.searchLocation,
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: AppTextStyles.body1,
                  ),
                  const SizedBox(height: 14),

                  // Tab toggle
                  _buildTabToggle(l10n, tabIndex, ref),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: tabIndex == 0
                    ? const ParkingListView()
                    : const ParkingMapView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle(AppLocalizations l10n, int tabIndex, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem(
            l10n.list,
            Icons.list_rounded,
            tabIndex == 0,
            () => ref.read(homeTabIndexProvider.notifier).state = 0,
          ),
          _buildTabItem(
            l10n.map,
            Icons.map_rounded,
            tabIndex == 1,
            () => ref.read(homeTabIndexProvider.notifier).state = 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
      String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.subtitle2.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
