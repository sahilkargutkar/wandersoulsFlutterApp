import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/isLoginCubit/is_login_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/login/auth_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/login/auth_state.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/boarding_screens.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/login_screen.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/home_bottom_bar.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/search_screen.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_article.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_destination.dart';
import 'package:wonder_souls/src/features/trips/model/blog_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/blog_detail_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/trip_wizard_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/destination_details.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/personal_info_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/travel_preferences_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/billing_subscriptions_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/upgrade_plan_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/payment_methods_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/account_security_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/help_support_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/terms_and_conditions_screen.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/add_booking_form_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/budget_expenses_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

List<String> _publicRoutes = [
  SplashScreen.routeName,
  LoginScreen.routeName,
  SignupScreen.routeName,
  BoardingScreens.routeName,
  TermsAndConditionsScreen.routeName,
];

GoRouter buildRouter({
  required IsLoginCubit isLoginCubit,
  required AuthCubit authCubit,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: SplashScreen.routeName,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.uri.toString();
      final isPublic = _publicRoutes.any((r) => r == '/' ? location == '/' : location.startsWith(r));

      debugPrint("GoRouter Redirect: location=$location, authState=${authState.runtimeType}, isPublic=$isPublic");

      if (authState is Authenticated &&
          isPublic &&
          location != SplashScreen.routeName) {
        debugPrint("GoRouter Redirect: Redirecting to HomeBottomBar");
        return HomeBottomBar.routeName;
      }

      if (authState is Unauthenticated && !isPublic) {
        debugPrint("GoRouter Redirect: Redirecting to LoginScreen");
        return LoginScreen.routeName;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: SignupScreen.routeName,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<SignUpCubit>(),
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: HomeBottomBar.routeName,
        builder: (context, state) => const HomeBottomBar(),
      ),
      GoRoute(
        path: SearchScreen.routeName,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: TripDetailsScreen.routeName,
        builder: (context, state) {
          final TripData trip;
          final extra = state.extra;
          if (extra is TripData) {
            trip = extra;
          } else if (extra is Map<String, dynamic>) {
            trip = TripData.fromJson(extra);
          } else {
            final args = ModalRoute.of(context)?.settings.arguments;
            if (args is TripData) {
              trip = args;
            } else if (args is Map<String, dynamic>) {
              trip = TripData.fromJson(args);
            } else {
              debugPrint("GoRouter Error: Trip data not found for TripDetailsScreen");
              return const Scaffold(
                body: Center(
                  child: Text("Error: Trip data could not be loaded."),
                ),
              );
            }
          }
          return TripDetailsScreen(trip: trip);
        },
      ),
      GoRoute(
        path: BoardingScreens.routeName,
        builder: (context, state) => const BoardingScreens(),
      ),
      GoRoute(
        path: ListDestination.routeName,
        builder: (context, state) => const ListDestination(),
      ),
      GoRoute(
        path: ListArticle.routeName,
        builder: (context, state) => const ListArticle(),
      ),
      GoRoute(
        path: BlogDetailScreen.routeName,
        builder: (context, state) {
          final BlogModel blog;
          final extra = state.extra;
          if (extra is BlogModel) {
            blog = extra;
          } else if (extra is Map<String, dynamic>) {
            blog = BlogModel.fromJson(extra);
          } else {
            debugPrint("GoRouter Error: Blog data not found for BlogDetailScreen");
            return const Scaffold(
              body: Center(
                child: Text("Error: Blog detail could not be loaded."),
              ),
            );
          }
          return BlogDetailScreen(blog: blog);
        },
      ),
      GoRoute(
        path: TripWizardScreen.routeName,
        builder: (context, state) {
          final PlaceModel place;
          final extra = state.extra;
          if (extra is PlaceModel) {
            place = extra;
          } else if (extra is Map<String, dynamic>) {
            place = PlaceModel.fromJson(extra);
          } else {
            final args = ModalRoute.of(context)?.settings.arguments;
            if (args is PlaceModel) {
              place = args;
            } else if (args is Map<String, dynamic>) {
              place = PlaceModel.fromJson(args);
            } else {
              debugPrint("GoRouter Error: Place data not found for TripWizardScreen");
              return const Scaffold(
                body: Center(
                  child: Text("Error: Destination details could not be loaded."),
                ),
              );
            }
          }
          return TripWizardScreen(destination: place);
        },
      ),
      GoRoute(
        path: DestinationDetailsScreen.routeName,
        builder: (context, state) {
          final PlaceModel place;
          final extra = state.extra;
          if (extra is PlaceModel) {
            place = extra;
          } else if (extra is Map<String, dynamic>) {
            place = PlaceModel.fromJson(extra);
          } else {
            final args = ModalRoute.of(context)?.settings.arguments;
            if (args is PlaceModel) {
              place = args;
            } else if (args is Map<String, dynamic>) {
              place = PlaceModel.fromJson(args);
            } else {
              debugPrint("GoRouter Error: Place data not found for DestinationDetailsScreen");
              return const Scaffold(
                body: Center(
                  child: Text("Error: Destination details could not be loaded."),
                ),
              );
            }
          }
          return DestinationDetailsScreen(place: place);
        },
      ),
      GoRoute(
        path: PersonalInfoScreen.routeName,
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: TravelPreferencesScreen.routeName,
        builder: (context, state) => const TravelPreferencesScreen(),
      ),
      GoRoute(
        path: BillingSubscriptionsScreen.routeName,
        builder: (context, state) => const BillingSubscriptionsScreen(),
      ),
      GoRoute(
        path: UpgradePlanScreen.routeName,
        builder: (context, state) => const UpgradePlanScreen(),
      ),
      GoRoute(
        path: PaymentMethodsScreen.routeName,
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: AccountSecurityScreen.routeName,
        builder: (context, state) => const AccountSecurityScreen(),
      ),
      GoRoute(
        path: HelpSupportScreen.routeName,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: TermsAndConditionsScreen.routeName,
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: AddBookingFormScreen.routeName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AddBookingFormScreen(
            tripId: extra['tripId'] as String,
            bookingType: extra['bookingType'] as String,
          );
        },
      ),
      GoRoute(
        path: BudgetExpensesScreen.routeName,
        builder: (context, state) {
          final trip = state.extra as TripData;
          return BudgetExpensesScreen(trip: trip);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Screen does not exist! ${state.error}')),
    ),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
