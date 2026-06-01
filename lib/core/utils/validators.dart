import '../localization/app_localizations.dart';

class Validators {
  Validators._();

  static String? validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.translate('fieldRequired');
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,10}$');
    if (!emailRegex.hasMatch(value)) return l10n.translate('invalidEmail');
    return null;
  }

  static String? validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.translate('fieldRequired');
    if (value.length < 6) return l10n.translate('passwordTooShort');
    return null;
  }

  static String? validateRequired(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.translate('fieldRequired');
    return null;
  }

  static String? validatePhone(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return null; // Optional
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value)) return l10n.translate('invalidPhone');
    return null;
  }

  static String? validateConfirmPassword(String? value, String password, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.translate('fieldRequired');
    if (value != password) return l10n.translate('passwordNotMatch');
    return null;
  }
}
