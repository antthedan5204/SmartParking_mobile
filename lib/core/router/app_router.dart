import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/parking/presentation/pages/home_page.dart';
import '../../features/parking/presentation/pages/my_bookings_page.dart';
import '../../features/parking/presentation/pages/parking_search_page.dart';
import '../../features/parking/presentation/pages/notifications_page.dart';
import '../../features/parking/presentation/pages/main_shell_page.dart';
import '../../features/parking/presentation/pages/vehicle_management_page.dart';
import '../../features/parking/presentation/pages/payment_success_page.dart';
import '../../features/parking/domain/entities/booking.dart';
import '../../features/parking/domain/entities/payment.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';

/// A [ChangeNotifier] that triggers GoRouter redirect re-evaluation
/// without recreating the entire router instance.
class _AuthChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();

  // Listen to auth changes and notify the router to re-evaluate redirects.
  // This avoids recreating GoRouter (and losing navigation stack) on every
  // auth state change.
  ref.listen<AuthState>(authProvider, (_, __) {
    authNotifier.notify();
  });

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      
      // Chờ cho đến khi trạng thái auth thoát khỏi 'initial'
      if (status == AuthStatus.initial) {
        return null; // Ở lại splash
      }

      final isLoggedIn = authState.user != null;
      final isSplashRoute = state.matchedLocation == '/splash';
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isResetPasswordRoute = state.matchedLocation == '/reset-password';

      // Nếu chưa đăng nhập và không ở các trang auth/splash, chuyển về login
      if (!isLoggedIn && !isLoginRoute && !isRegisterRoute && !isSplashRoute && !isResetPasswordRoute) {
        return '/login';
      }

      // Nếu đã đăng nhập hoặc đã xác định là chưa đăng nhập, và đang ở splash
      if (isSplashRoute) {
        if (isLoggedIn) {
          if ((authState.user?.isAdmin ?? false) || (authState.user?.isManager ?? false)) {
            return '/admin';
          }
          return '/home';
        } else {
          return '/login';
        }
      }

      // Nếu đã đăng nhập và đang ở trang login, chuyển về home phù hợp
      if (isLoggedIn && isLoginRoute) {
        if ((authState.user?.isAdmin ?? false) || (authState.user?.isManager ?? false)) {
          return '/admin';
        }
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final email = extras['email'] as String? ?? '';
          return ResetPasswordPage(email: email);
        },
      ),

      // ---------- Bottom Navigation Shell ----------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellPage(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0 – Trang chủ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomePage(),
                ),
              ),
            ],
          ),
          // Tab 1 – Đơn đặt
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                name: 'bookings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MyBookingsPage(),
                ),
              ),
            ],
          ),
          // Tab 2 – Đặt chỗ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parking',
                name: 'parking',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ParkingSearchPage(),
                ),
              ),
            ],
          ),
          // Tab 3 – Thông báo
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                name: 'notifications',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: NotificationsPage(),
                ),
              ),
            ],
          ),
          // Tab 4 – Tài khoản
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfilePage(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ---------- Admin ----------
      GoRoute(
        path: '/admin',
        name: 'admin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminDashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/vehicles',
        name: 'vehicles',
        builder: (context, state) => const VehicleManagementPage(),
      ),
      GoRoute(
        path: '/payment-success',
        name: 'payment-success',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return PaymentSuccessPage(
            booking: extras['booking'] as Booking,
            payment: extras['payment'] as Payment,
          );
        },
      ),
    ],
  );
});
