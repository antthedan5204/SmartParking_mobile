import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1;
  String _token = "";

  // OTP Focus Nodes and Controllers
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _nextStep() async {
    final token = _otpControllers.map((c) => c.text).join();
    if (token.length != 6) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('pleaseEnter6Digits')),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyResetToken(
          email: widget.email,
          token: token,
        );

    if (mounted && success) {
      _token = token;
      setState(() {
        _step = 2;
      });
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('passwordsDoNotMatch')),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    final success = await ref.read(authProvider.notifier).resetPassword(
          email: widget.email,
          token: _token,
          newPassword: _passwordController.text,
        );

    if (mounted && success) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('resetPasswordSuccess')),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/login');
    }
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (index < 5) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  _focusNodes[index].unfocus();
                  _nextStep(); // Tự động chuyển qua bước sau nếu nhập xong 6 số
                }
              } else {
                if (index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate(next.errorMessage!)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.translate('resetPassword')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step == 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step = 1),
              )
            : const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_step == 1) ...[
                  Text(
                    l10n.translate('enterResetOtpDesc').replaceAll('{email}', widget.email),
                    style: AppTextStyles.body1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildOtpInput(),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: authState.status == AuthStatus.loading
                          ? null
                          : _nextStep,
                      child: authState.status == AuthStatus.loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : Text(l10n.translate('continueText'), style: AppTextStyles.button),
                    ),
                  ),
                ] else ...[
                  Text(
                    l10n.translate('createNewPasswordDesc'),
                    style: AppTextStyles.body1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    label: l10n.translate('newPassword'),
                    hint: l10n.translate('enterNewPassword'),
                    controller: _passwordController,
                    isPassword: true,
                    validator: (val) => Validators.validatePassword(val, l10n),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: l10n.translate('confirmNewPasswordLabel'),
                    hint: l10n.translate('enterConfirmNewPassword'),
                    controller: _confirmPasswordController,
                    isPassword: true,
                    validator: (val) => Validators.validateConfirmPassword(
                      val,
                      _passwordController.text,
                      l10n
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: authState.status == AuthStatus.loading
                          ? null
                          : _handleResetPassword,
                      child: authState.status == AuthStatus.loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : Text(
                              l10n.translate('changePasswordBtn'),
                              style: AppTextStyles.button,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
