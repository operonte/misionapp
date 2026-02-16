import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/person_detail_screen.dart';
import 'screens/person_form_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/terms_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/person/new',
        builder: (_, __) => const PersonFormScreen(),
      ),
      GoRoute(
        path: '/person/edit/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return PersonFormScreen(personId: id);
        },
      ),
      GoRoute(
        path: '/person/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return PersonDetailScreen(personId: id);
        },
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      GoRoute(path: '/contact', builder: (_, __) => const ContactScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
    ],
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;

      if (location == '/splash') return null;

      final onboardingDone = await appStorage.isOnboardingDone();
      // Primera vez: mostrar onboarding antes de login.
      if (!onboardingDone && location != '/onboarding') {
        return '/onboarding';
      }

      if (user == null) {
        if (location != '/login' && location != '/onboarding') return '/login';
        return null;
      }

      // Usuario logueado que viene del login → home.
      if (onboardingDone && location == '/login') {
        return '/home';
      }
      return null;
    },
  );
}
