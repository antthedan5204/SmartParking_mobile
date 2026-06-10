import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../../../../core/localization/app_localizations.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final success = await ref
        .read(authProvider.notifier)
        .updateProfile(
          id: user.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('updateSuccess'),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorKey = ref.read(authProvider).errorMessage;
        final error = errorKey != null
            ? AppLocalizations.of(context).translate(errorKey)
            : AppLocalizations.of(context).translate('updateFailed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    AppLocalizations.of(context).translate('personalInfo'),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    child: Column(
                      children: [
                        _buildProfileItem(
                          label: AppLocalizations.of(
                            context,
                          ).translate('fullName'),
                          controller: _nameController,
                          icon: Icons.person_rounded,
                          enabled: _isEditing,
                          color: const Color(
                            0xFF1E293B,
                          ), // Unified color, no background
                        ),
                        _buildDivider(),
                        _buildProfileItem(
                          label: AppLocalizations.of(
                            context,
                          ).translate('phone'),
                          controller: _phoneController,
                          icon: Icons.phone_android_rounded,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          color: const Color(
                            0xFF1E293B,
                          ), // Unified color, no background
                        ),
                        _buildDivider(),
                        _buildReadOnlyItem(
                          label: AppLocalizations.of(
                            context,
                          ).translate('email'),
                          value: user?.email ?? '',
                          icon: Icons.alternate_email_rounded,
                          color: const Color(0xFF1E293B),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    AppLocalizations.of(
                      context,
                    ).translate('vehicleAndSecurity'),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    child: Column(
                      children: [
                        _buildSettingsAction(
                          label: AppLocalizations.of(
                            context,
                          ).translate('manageLicensePlates'),
                          icon: Icons.directions_car_filled_rounded,
                          color: const Color(0xFF6366F1),
                          onTap: () => context.push('/vehicles'),
                        ),
                        _buildDivider(),
                        _buildReadOnlyItem(
                          label: AppLocalizations.of(context).translate('role'),
                          value: user?.role ?? 'User',
                          icon: Icons.verified_user_rounded,
                          color: const Color(0xFF1E293B),
                        ),
                        _buildDivider(),
                        _buildSettingsAction(
                          label: AppLocalizations.of(
                            context,
                          ).translate('changePassword'),
                          icon: Icons.lock_person_rounded,
                          color: const Color(0xFFEF4444),
                          onTap: () => _showChangePasswordDialog(context, ref),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    AppLocalizations.of(context).translate('otherOptions'),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    child: Column(
                      children: [
                        _buildSettingsAction(
                          label: AppLocalizations.of(
                            context,
                          ).translate('languageSettings'),
                          icon: Icons.translate_rounded,
                          color: const Color(0xFF1E293B),
                          onTap: () => _showLanguageSelector(context, ref),
                        ),
                        _buildDivider(),
                        _buildSettingsAction(
                          label: AppLocalizations.of(
                            context,
                          ).translate('helpCenter'),
                          icon: Icons.help_outline_rounded,
                          color: const Color(0xFF1E293B),
                          onTap: () {
                            context.push('/help-center');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  if (_isEditing)
                    _buildActionButtons(context, isLoading)
                  else
                    _buildEditButton(context),

                  const SizedBox(height: 20),
                  _buildLogoutButton(context, ref),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic user) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF334155),
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 54,
                        backgroundColor: Color(0xFF0F172A),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFF1E293B),
                          child: Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? AppLocalizations.of(context).translate('guest'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }

  Widget _buildProfileItem({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(top: 4, bottom: 4),
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ],
            ),
          ),
          if (enabled)
            const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildReadOnlyItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 38,
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => setState(() => _isEditing = true),
        icon: const Icon(Icons.mode_edit_outline_rounded, size: 20),
        label: Text(AppLocalizations.of(context).translate('editProfile')),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: isLoading
                  ? null
                  : () => setState(() => _isEditing = false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              child: Text(
                AppLocalizations.of(context).translate('cancel').toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(
                        context,
                      ).translate('save').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton.icon(
        onPressed: () => _showLogoutDialog(context, ref),
        icon: const Icon(
          Icons.logout_rounded,
          size: 20,
          color: Color(0xFFEF4444),
        ),
        label: Text(
          AppLocalizations.of(context).translate('logoutAccount'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFEF4444),
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            AppLocalizations.of(context).translate('confirmAction'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLocalizations.of(context).translate('confirmPasswordChange'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocalizations.of(context).translate('decline'),
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);

                // Hiển thị loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingCtx) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );

                final success = await ref
                    .read(authProvider.notifier)
                    .sendPasswordResetEmail(user.email);

                if (context.mounted) {
                  // Đóng loading dialog
                  Navigator.of(context, rootNavigator: true).pop();

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context).translate('otpSent'),
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.push(
                      '/reset-password',
                      extra: {'email': user.email},
                    );
                  } else {
                    final errorKey = ref.read(authProvider).errorMessage;
                    final error = errorKey != null
                        ? AppLocalizations.of(context).translate(errorKey)
                        : AppLocalizations.of(
                            context,
                          ).translate('sendOtpFailed');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppLocalizations.of(context).translate('accept')),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            AppLocalizations.of(context).translate('confirmAction'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLocalizations.of(context).translate('confirmLogout'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocalizations.of(context).translate('later'),
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).translate('logout').toUpperCase(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentLocale = ref.watch(localeProvider).languageCode;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).translate('selectLanguage'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(
                  AppLocalizations.of(context).translate('vietnamese'),
                ),
                trailing: currentLocale == 'vi'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('vi'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context).translate('english')),
                trailing: currentLocale == 'en'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
