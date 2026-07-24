import 'package:flutter/material.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/boarding_screens.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/login_screen.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/home_bottom_bar.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_article.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_destination.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/destination_explorer_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard_screen.dart';

Route<dynamic> generateRoute(RouteSettings routeSettings) {
  switch (routeSettings.name) {
    case SplashScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => SplashScreen(),
      );
    case LoginScreen.routeName:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case HomeBottomBar.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => HomeBottomBar(),
      );
    case TripDetailsScreen.routeName:
      var arg = routeSettings.arguments;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => TripDetailsScreen(trip: arg as Trip?),
      );
    case BoardingScreens.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => BoardingScreens(),
      );
    case ListDestination.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => ListDestination(),
      );
    case ListArticle.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => ListArticle(),
      );
    case DestinationExplorerScreen.routeName:
      var arg = routeSettings.arguments;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => DestinationExplorerScreen(
          destination: arg as Map<String, String>,
        ),
      );
    case TripWizardScreen.routeName:
      var arg = routeSettings.arguments;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => TripWizardScreen(
          destination: arg as Map<String, String>,
        ),
      );
    default:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => Scaffold(
          body: Center(child: Text('Screen does not exist! $routeSettings')),
        ),
      );
  }
}
