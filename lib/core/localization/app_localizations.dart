import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<bool> load() async {
    final jsonString =
        await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Convenience getters
  String get appName => translate('appName');
  String get findParking => translate('findParking');
  String get user => translate('user');
  String get admin => translate('admin');
  String get email => translate('email');
  String get emailHint => translate('emailHint');
  String get password => translate('password');
  String get passwordHint => translate('passwordHint');
  String get login => translate('login');
  String get loginAsAdmin => translate('loginAsAdmin');
  String get forgotPassword => translate('forgotPassword');
  String get noAccount => translate('noAccount');
  String get register => translate('register');
  String get back => translate('back');
  String get fullName => translate('fullName');
  String get fullNameHint => translate('fullNameHint');
  String get phone => translate('phone');
  String get phoneHint => translate('phoneHint');
  String get licensePlate => translate('licensePlate');
  String get licensePlateHint => translate('licensePlateHint');
  String get confirmPassword => translate('confirmPassword');
  String get hello => translate('hello');
  String get logout => translate('logout');
  String get list => translate('list');
  String get map => translate('map');
  String get searchLocation => translate('searchLocation');
  String get evChargingSpots => translate('evChargingSpots');
  String get occupancy => translate('occupancy');
  String get free => translate('free');
  String get pricePerHour => translate('pricePerHour');
  String get navigateToSpot => translate('navigateToSpot');
  String get available => translate('available');
  String get taken => translate('taken');
  String get adminPanel => translate('adminPanel');
  String get dashboard => translate('dashboard');
  String get zones => translate('zones');
  String get sensors => translate('sensors');
  String get reports => translate('reports');
  String get totalSlots => translate('totalSlots');
  String get availableSlots => translate('availableSlots');
  String get occupancyRate => translate('occupancyRate');
  String get revenue7Days => translate('revenue7Days');
  String get generateReport => translate('generateReport');
  String get exportPdf => translate('exportPdf');
  String get exportExcel => translate('exportExcel');
  String get revenueChart => translate('revenueChart');
  String get occupancyByHour => translate('occupancyByHour');
  String get revenueVnd => translate('revenueVnd');
  String get currency => translate('currency');
  String get language => translate('language');
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');
  String get fieldRequired => translate('fieldRequired');
  String get invalidEmail => translate('invalidEmail');
  String get passwordTooShort => translate('passwordTooShort');
  String get passwordNotMatch => translate('passwordNotMatch');
  String get loginSuccess => translate('loginSuccess');
  String get loginFailed => translate('loginFailed');
  String get registerSuccess => translate('registerSuccess');
  String get registerFailed => translate('registerFailed');
  String get networkError => translate('networkError');
  String get serverError => translate('serverError');
  String get unknownError => translate('unknownError');
  String get retry => translate('retry');
  String get noData => translate('noData');
  String get loading => translate('loading');
  String get staff => translate('staff');
  String get staffManagement => translate('staffManagement');
  String get createManager => translate('createManager');
  String get manager => translate('manager');
  String get create => translate('create');
  String get cancel => translate('cancel');
  String get success => translate('success');
  String get roleLabel => translate('role');
  
  // New keys for detail view and booking
  String get address => translate('address');
  String get price => translate('price');
  String get workingHours => translate('workingHours');
  String get nonStop => translate('nonStop');
  String get characteristics => translate('characteristics');
  String get payParking => translate('payParking');
  String get paymentSuccess => translate('paymentSuccess');
  String get spotReserved => translate('spotReserved');
  String get reservedFor => translate('reservedFor');
  String get validUntil => translate('validUntil');
  String get totalPaid => translate('totalPaid');
  String get chooseMethod => translate('chooseMethod');
  String get momo => translate('momo');
  String get vnpay => translate('vnpay');
  String get confirmPayment => translate('confirmPayment');
  String get processing => translate('processing');
  
  // Map and Location
  String get locateOnMap => translate('locateOnMap');
  String get refineLocation => translate('refineLocation');
  String get distance => translate('distance');
  String get route => translate('route');
  String get myLocation => translate('myLocation');
  String get calculatingRoute => translate('calculatingRoute');
  String get precisePosition => translate('precisePosition');
  String get confirmed => translate('confirmed');
  String get completed => translate('completed');
  String get cancelled => translate('cancelled');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Riverpod provider for locale management
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('vi')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(AppConstants.languageKey) ?? 'vi';
    state = Locale(langCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.languageKey, locale.languageCode);
  }

  void toggleLocale() {
    if (state.languageCode == 'vi') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('vi'));
    }
  }
}
