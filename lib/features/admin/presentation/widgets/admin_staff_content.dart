import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/user_management_provider.dart';
import 'create_staff_dialog.dart';

class AdminStaffContent extends ConsumerStatefulWidget {
  const AdminStaffContent({super.key});

  @override
  ConsumerState<AdminStaffContent> createState() => _AdminStaffContentState();
}

class _AdminStaffContentState extends ConsumerState<AdminStaffContent> {
  @override
  void initState() {
    super.initState();
    // Load users on mount if not already loading or loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userManagementProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(userManagementProvider);

    return Column(
      children: [
        // Tab Header/Action
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.staffManagement,
                  style: AppTextStyles.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showCreateStaffDialog(context, ref),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: Text(l10n.createManager),
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

        // List of Staff
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.users.isEmpty
                  ? Center(child: Text(l10n.noData))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];
                        return _buildStaffItem(context, user, l10n);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStaffItem(BuildContext context, dynamic user, AppLocalizations l10n) {
    final isManager = user.isManager;
    final isAdmin = user.isAdmin;
    
    // Only show staff (Managers/Admins), hide regular customers if any in this list
    if (!isManager && !isAdmin) return const SizedBox.shrink();

    return Container(
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
          CircleAvatar(
            backgroundColor: isAdmin ? AppColors.danger.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: isAdmin ? AppColors.danger : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppTextStyles.subtitle1),
                Text(user.email, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAdmin ? AppColors.danger.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAdmin ? l10n.admin : l10n.manager,
              style: AppTextStyles.caption.copyWith(
                color: isAdmin ? AppColors.danger : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateStaffDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreateStaffDialog(),
    );

    if (result == true) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('createStaffSuccess')),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(userManagementProvider.notifier).loadUsers();
      }
    }
  }
}
