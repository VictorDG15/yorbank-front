import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/accounts/presentation/account_detail_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/onboarding_page.dart';
import '../../features/auth/presentation/otp_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/cards/presentation/cards_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/loans/presentation/loan_simulator_page.dart';
import '../../features/operations/presentation/operations_page.dart';
import '../../features/payments/presentation/payment_flow_pages.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/security/presentation/security_settings_page.dart';
import '../../features/transfers/presentation/transfer_confirm_page.dart';
import '../../features/transfers/presentation/transfer_form_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/otp', builder: (_, __) => const OtpPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(path: '/operations', builder: (_, __) => const OperationsPage()),
      GoRoute(
        path: '/accounts/detail',
        builder: (_, __) => const AccountDetailPage(),
      ),
      GoRoute(
        path: '/transfers/new',
        builder: (_, __) => const TransferFormPage(),
      ),
      GoRoute(
        path: '/transfers/confirm',
        builder: (_, __) => const TransferConfirmPage(),
      ),
      GoRoute(path: '/cards', builder: (_, __) => const CardsPage()),
      GoRoute(
        path: '/payments/services',
        builder: (_, __) => const ServicePaymentPage(),
      ),
      GoRoute(path: '/payments/yape', builder: (_, __) => const YapePaymentPage()),
      GoRoute(
        path: '/payments/recharges',
        builder: (_, __) => const MobileRechargePage(),
      ),
      GoRoute(path: '/loans', builder: (_, __) => const LoanSimulatorPage()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(
        path: '/security',
        builder: (_, __) => const SecuritySettingsPage(),
      ),
    ],
  );
});
