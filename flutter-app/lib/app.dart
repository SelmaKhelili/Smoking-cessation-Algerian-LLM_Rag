import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/features/profile/presentation/pages/profilepage.dart';
import 'package:my_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:my_app/features/podcasts/presentation/pages/podcasts_page.dart';
import 'package:my_app/features/chatbot/presentation/pages/chatbots_list_page.dart';
import 'package:my_app/features/achievements/presentation/pages/achievements_page.dart';
import 'package:my_app/features/navigation/presentation/pages/main_navigation_page.dart';
import 'core/routes/app_routes.dart';
import 'features/splash/presentation/bloc/splash_bloc.dart';
import 'features/splash/presentation/bloc/splash_event.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/splash/presentation/pages/welcome_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/auth/presentation/pages/set_password_page.dart';
import 'features/healthcheck/presentation/pages/health_check_page.dart';


class SAIApp extends StatelessWidget {
  const SAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SplashBloc>(
          create: (_) => SplashBloc()..add(SplashStarted()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SAI',
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashPage(),
          AppRoutes.welcome: (_) => const WelcomePage(),
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.signup: (_) => const SignUpPage(),
          AppRoutes.setpasswordpage: (_) => const SetPasswordPage(), 
          AppRoutes.home: (_) => const MainNavigationPage(),
          AppRoutes.mainNavigation: (_) => const MainNavigationPage(),
          AppRoutes.healthCheck: (_) => const HealthCheckPage(),
          AppRoutes.profilepage: (_) => const ProfilePage(),
          AppRoutes.editprofilepage: (_) => const EditProfilePage(),
          AppRoutes.podcastspage: (_) => const PodcastPage(),
          AppRoutes.chatbots_list_page: (_) => const ChatbotPage(),
          AppRoutes.achievements: (_) => const AchievementsPage(),
        },
      ),
    );
  }
}
