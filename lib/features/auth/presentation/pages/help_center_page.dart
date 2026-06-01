import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';

class HelpCenterPage extends ConsumerWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.translate('helpCenterTitle')),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQs
            Text(
              l10n.translate('faq'),
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context,
              l10n.translate('howToBook'),
              l10n.translate('howToBookDesc'),
            ),
            _buildFaqItem(
              context,
              l10n.translate('howToCancel'),
              l10n.translate('howToCancelDesc'),
            ),
            _buildFaqItem(
              context,
              l10n.translate('howToExtend'),
              l10n.translate('howToExtendDesc'),
            ),

            const SizedBox(height: 32),

            // Contact Us
            Text(
              l10n.translate('contactUs'),
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.phone_rounded,
              title: l10n.translate('hotline'),
              subtitle: '1900 1555',
              onTap: () {
                // Implement phone call logic using url_launcher
              },
            ),
            _buildContactItem(
              icon: Icons.email_rounded,
              title: l10n.translate('emailSupport'),
              subtitle: 'support@smartparking.com',
              onTap: () {
                // Implement email launch logic
              },
            ),

            const SizedBox(height: 32),

            // Send Request Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('processing')),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  l10n.translate('sendRequest'),
                  style: AppTextStyles.button,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              answer,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTextStyles.subtitle1),
        subtitle: Text(subtitle, style: AppTextStyles.body2.copyWith(color: AppColors.primary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}
