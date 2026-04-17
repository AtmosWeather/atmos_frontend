import 'package:flutter/material.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/weather/presentation/pages/home_page.dart';
import '../../features/planner/presentation/pages/planner_page.dart';
import '../../features/ai_assistant/presentation/pages/ai_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/manage_account_page.dart';
import '../../features/settings/presentation/pages/about_app_page.dart';
import '../../features/settings/presentation/pages/feedback_page.dart';
import '../../features/settings/presentation/pages/units_page.dart';
import '../../features/settings/presentation/pages/theme_page.dart';
import '../../features/settings/presentation/pages/notification_page.dart';
import '../../features/settings/presentation/pages/help_page.dart';
import '../../features/settings/presentation/pages/policy_terms_page.dart';

import '../../features/admin/presentation/pages/admin_landing_page.dart';

class AppRoutes {
  static const splash = '/';
  static const signin = '/signin';
  static const signup = '/signup';
  static const home = '/home';
  static const planner = '/planner';
  static const ai = '/ai';
  static const news = '/news';
  static const settings = '/settings';
  static const admin = '/admin';
  static const manageAccount = '/manage_account';
  static const aboutApp = '/about_app';
  static const feedback = '/feedback';
  static const units = '/units';
  static const theme = '/theme';
  static const notification = '/notification';
  static const help = '/help';
  static const terms = '/terms';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashPage(),
    signin: (context) => const SignInPage(),
    signup: (context) => const SignUpPage(),
    home: (context) => const LandingPage(),
    planner: (context) => const PlannerPage(),
    ai: (context) => const AiPage(),
    news: (context) => const NewsPage(),
    settings: (context) => const SettingsPage(),
    admin: (context) => const AdminLandingPage(),
    manageAccount: (context) => const ManageAccountPage(),
    aboutApp: (context) => const AboutAppPage(),
    feedback: (context) => const FeedbackPage(),
    units: (context) => const UnitsPage(),
    theme: (context) => const ThemePage(),
    notification: (context) => const NotificationPage(),
    help: (context) => const HelpPage(),
    terms: (context) => const PolicyTermsPage(),
  };
}
