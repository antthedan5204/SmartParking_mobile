import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/services/realtime_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/parking/presentation/pages/notifications_page.dart';

class SmartParkingApp extends ConsumerStatefulWidget {
  const SmartParkingApp({super.key});

  @override
  ConsumerState<SmartParkingApp> createState() => _SmartParkingAppState();
}

class _SmartParkingAppState extends ConsumerState<SmartParkingApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Eagerly initialize notifications provider so it catches all SignalR events
      ref.read(notificationsProvider);
      unawaited(_syncRealtimeConnection(ref.read(authProvider)));
    });
  }

  Future<void> _syncRealtimeConnection(AuthState authState) async {
    if (authState.status == AuthStatus.authenticated) {
      final storage = ref.read(secureStorageProvider);
      final token = authState.user?.token ??
          await storage.read(key: AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        await RealtimeNotificationService().connect(token);
      }
    } else {
      await RealtimeNotificationService().disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      unawaited(_syncRealtimeConnection(next));
    });

    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Smart Parking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
