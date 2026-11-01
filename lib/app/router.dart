import 'package:flutter/material.dart';

import '../features/history/presentation/pages/history_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/recommendation/presentation/pages/recommendation_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/sleep_planner/presentation/pages/sleep_planner_page.dart';
import '../features/sleep_quality/presentation/pages/sleep_quality_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/home/presentation/pages/suggested_bedtimes_page.dart';

class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const sleepPlanner = '/sleep-planner';
  static const sleepQuality = '/sleep-quality';
  static const recommendation = '/recommendation';
  static const history = '/history';
  static const settings = '/settings';
  static const splash = '/splash';
  static const suggestedBedtimes = '/suggested-bedtimes';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case AppRoutes.sleepPlanner:
        return MaterialPageRoute(builder: (_) => const SleepPlannerPage());
      case AppRoutes.sleepQuality:
        return MaterialPageRoute(builder: (_) => const SleepQualityPage());
      case AppRoutes.recommendation:
        return MaterialPageRoute(builder: (_) => const RecommendationPage());
      case AppRoutes.history:
        return MaterialPageRoute(builder: (_) => const HistoryPage());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case AppRoutes.suggestedBedtimes:
        return MaterialPageRoute(builder: (_) => const SuggestedBedtimesPage());
        default:
          return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }
}
