import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/user_management_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/admin_staff_content.dart';
import '../widgets/admin_zones_content.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/occupancy_chart.dart';
import '../widgets/admin_bookings_content.dart';
import '../providers/booking_management_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(adminDashboardProvider);
    final locale = ref.watch(localeProvider);
    final userName = authState.user?.name ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Dark admin header
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.adminGradient,
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.adminPanel,
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.textOnDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.hello}, $userName',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textOnDark.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Language toggle
                          GestureDetector(
                            onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                locale.languageCode.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              ref.read(authProvider.notifier).logout();
                              context.go('/login');
                            },
                            icon: const Icon(
                              Icons.logout,
                              color: AppColors.textOnDark,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab navigation
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildAdminTab(
                          icon: Icons.dashboard_outlined,
                          label: l10n.dashboard,
                          isSelected: dashboardState.selectedTab == 0,
                          onTap: () =>
                              ref.read(adminDashboardProvider.notifier).setTab(0),
                        ),
                        _buildAdminTab(
                          icon: Icons.location_on_outlined,
                          label: l10n.zones,
                          isSelected: dashboardState.selectedTab == 1,
                          onTap: () =>
                              ref.read(adminDashboardProvider.notifier).setTab(1),
                        ),
                        if (authState.user?.isAdmin ?? false)
                          _buildAdminTab(
                            icon: Icons.people_outline,
                            label: l10n.staff,
                            isSelected: dashboardState.selectedTab == 3,
                            onTap: () {
                              ref.read(adminDashboardProvider.notifier).setTab(3);
                              ref.read(userManagementProvider.notifier).loadUsers();
                            },
                          ),
                        _buildAdminTab(
                          icon: Icons.book_online_outlined,
                          label: 'Đơn đặt',
                          isSelected: dashboardState.selectedTab == 4,
                          onTap: () {
                            ref.read(adminDashboardProvider.notifier).setTab(4);
                            ref.read(bookingManagementProvider.notifier).loadBookings();
                          },
                        ),
                        _buildAdminTab(
                          icon: Icons.history,
                          label: 'Lịch sử',
                          isSelected: dashboardState.selectedTab == 5,
                          onTap: () {
                            ref.read(adminDashboardProvider.notifier).setTab(5);
                            ref.read(bookingManagementProvider.notifier).loadBookings();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Content
            Expanded(
              child: dashboardState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : (dashboardState.selectedTab == 3)
                      ? const AdminStaffContent()
                      : (dashboardState.selectedTab == 4)
                          ? const AdminBookingsContent(isHistoryView: false)
                          : (dashboardState.selectedTab == 5)
                              ? const AdminBookingsContent(isHistoryView: true)
                              : (dashboardState.selectedTab == 1)
                                  ? const AdminZonesContent()
                                  : _buildDashboardContent(context, dashboardState, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    AdminDashboardState state,
    AppLocalizations l10n,
  ) {
    final stats = state.stats;

    if (stats == null) {
      return Center(
        child: Text(l10n.noData, style: AppTextStyles.body2),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh will be handled by the provider
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI cards grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: l10n.totalSlots,
                  value: stats.totalSlots.toString(),
                  icon: Icons.local_parking,
                  color: AppColors.info,
                ),
                StatCard(
                  title: l10n.availableSlots,
                  value: stats.availableSlots.toString(),
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  trend: '+5%',
                ),
                StatCard(
                  title: l10n.occupancyRate,
                  value: '${stats.occupancyPercent.toStringAsFixed(1)}%',
                  icon: Icons.pie_chart_outline,
                  color: AppColors.warning,
                  trend: '+2.3%',
                ),
                StatCard(
                  title: l10n.revenue7Days,
                  value: _formatCurrency(stats.revenue7Days),
                  icon: Icons.attach_money,
                  color: AppColors.primary,
                  trend: '+8%',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Revenue chart
            RevenueChart(
              dailyStats: stats.dailyStats,
              title: l10n.revenueChart,
            ),
            const SizedBox(height: 16),

            // Occupancy chart
            OccupancyChart(
              hourlyData: stats.hourlyOccupancy,
              title: l10n.occupancyByHour,
            ),
            const SizedBox(height: 16),

            // Report generation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.generateReport, style: AppTextStyles.subtitle1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(ApiEndpoints.exportPdf);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: Text(l10n.exportPdf),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(ApiEndpoints.exportExcel);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.table_chart, size: 18),
                          label: Text(l10n.exportExcel),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.textOnPrimary
                  : AppColors.textOnDark.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.buttonSmall.copyWith(
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textOnDark.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
